import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "root:/theme"

PanelWindow {
    id: settingsWindow

    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:settings"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    property var wifiPrompt: null
    property int activeSettingsTab: 0
    property string targetConnectSSID: ""
    property string wifiSSID: ""
    property bool wifiRadioActive: false
    property string connectingSSID: ""
    property var wifiNetworks: []
    property var keybindsList: []

    // Dynamic Wallpaper properties
    property var wallpapersList: []
    property string wallpaperDir: { let home = Quickshell.env("HOME"); return Theme.currentLang === "es" ? home + "/Imágenes/Wallpapers" : home + "/Pictures/Wallpapers"; }

    // Dynamic Language properties
    property var languagesList: []
    property bool showAddLang: false
    property string newLangCode: ""
    property string newLangName: ""

    // Dismissal / Entrance Animations state
    property bool active: false

    // Add Bind properties
    property bool showAddBind: false
    property string newKeysInput: ""
    property string newCmdInput: ""

    // Close timer to wait for slide/fade out animation
    Timer {
        id: closeTimer
        interval: 220
        onTriggered: {
            settingsWindow.visible = false;
        }
    }

    function closePanel() {
        active = false;
        closeTimer.start();
    }

    function toggle() {
        if (active) {
            closePanel();
        } else {
            closeTimer.stop();
            settingsWindow.visible = true;
            active = true;
        }
    }

    onVisibleChanged: {
        if (visible) {
            activeSettingsTab = 0;
            showAddBind = false;
            showAddLang = false;
            netProcess.running = true;
            wifiScanProcess.running = true;
            listLangsProcess.running = true;
            listWallpapersProcess.command = ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/list_wallpapers.py", settingsWindow.wallpaperDir];
            listWallpapersProcess.running = true;
        }
    }

    onWallpaperDirChanged: {
        if (settingsWindow.visible) {
            listWallpapersProcess.command = ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/list_wallpapers.py", settingsWindow.wallpaperDir];
            listWallpapersProcess.running = true;
        }
    }

    // 1. Network Polling inside Settings (only when visible!)
    Timer {
        id: netTimer
        interval: 3000
        running: settingsWindow.visible
        repeat: true
        onTriggered: netProcess.running = true
    }

    Process {
        id: netProcess
        command: ["sh", "-c", "default_iface=$(ip route show | grep '^default' | awk '{print $5}'); if [ -n \"$default_iface\" ]; then connection_type=$(udevadm info --query=property --path=/sys/class/net/$default_iface 2>/dev/null | grep -q 'ID_NET_NAME_MAC' && echo 'ethernet' || echo 'wifi'); if [ \"$connection_type\" = 'wifi' ]; then ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2); ip_addr=$(ip addr show dev $default_iface | grep 'inet ' | awk '{print $2}' | cut -d/ -f1); else ssid=''; ip_addr=$(ip addr show dev $default_iface | grep 'inet ' | awk '{print $2}' | cut -d/ -f1); fi; else connection_type='none'; ssid=''; ip_addr=''; fi; wifi_radio=$(nmcli radio wifi); echo \"type:$connection_type|ssid:$ssid|ip:$ip_addr|iface:$default_iface|radio:$wifi_radio\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|");
                let info = {};
                for (let part of parts) {
                    let kv = part.split(":");
                    if (kv.length >= 2) {
                        info[kv[0]] = kv[1];
                    }
                }
                settingsWindow.wifiSSID = info.ssid ?? "";
                settingsWindow.wifiRadioActive = (info.radio === "enabled");
            }
        }
    }

    // 2. Wifi Scanning Process
    Process {
        id: wifiScanProcess
        command: ["sh", "-c", "nmcli -t -f ssid,signal dev wifi 2>/dev/null | grep -v '^:' | sort -u -t: -k1,1 | head -n 8 | paste -sd '|' -"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("|");
                let networks = [];
                for (let line of lines) {
                    if (!line) continue;
                    let parts = line.split(":");
                    if (parts.length >= 2) {
                        let ssid = parts[0];
                        let signal = parseInt(parts[1]);
                        networks.push({ "ssid": ssid, "signal": signal });
                    }
                }
                settingsWindow.wifiNetworks = networks;
            }
        }
    }

    // Keybinds parsing & watching
    property FileView keybindsFile: FileView {
        path: Quickshell.env("HOME") + "/pro/dotfiles/hypr/modules/keybinds.lua"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            settingsWindow.keybindsList = settingsWindow.parseKeybinds(text());
        }
    }

    function parseKeybinds(luaContent) {
        const lines = luaContent.split("\n");
        const binds = [];
        for (let line of lines) {
            line = line.trim();
            if (line.startsWith("--") || line === "") continue;
            if (line.includes("hl.bind(")) {
                let match = line.match(/hl\.bind\(([^,]+),\s*([^,\)]+)/);
                if (match) {
                    let keysRaw = match[1].trim();
                    let actionRaw = match[2].trim();
                    let keys = keysRaw
                        .replace(/mainMod\s*\.\.\s*"/g, "SUPER")
                        .replace(/"/g, "")
                        .replace(/\.\./g, "+")
                        .replace(/\s*\+\s*/g, " + ")
                        .trim();
                    if (keys.startsWith("SUPER +  +")) {
                        keys = keys.replace("SUPER +  +", "SUPER +");
                    }
                    if (keys.endsWith("+")) {
                        keys = keys.slice(0, -1).trim();
                    }
                    let desc = actionRaw;
                    if (actionRaw.includes("exec_cmd")) {
                        let cmdMatch = actionRaw.match(/exec_cmd\(([^)]+)\)/);
                        if (cmdMatch) {
                            let cmd = cmdMatch[1].replace(/programs\./, "").replace(/"/g, "");
                            desc = "Ejecutar " + cmd;
                        }
                    } else if (actionRaw.includes("window.close")) {
                        desc = "Cerrar ventana";
                    } else if (actionRaw.includes("window.float")) {
                        desc = "Alternar flotante";
                    } else if (actionRaw.includes("window.pseudo")) {
                        desc = "Alternar modo pseudo";
                    } else if (actionRaw.includes("layout")) {
                        desc = "Alternar división de diseño";
                    } else if (actionRaw.includes("focus")) {
                        let dirMatch = actionRaw.match(/direction\s*=\s*"([^"]+)"/);
                        if (dirMatch) {
                            desc = "Enfocar " + dirMatch[1];
                        } else {
                            desc = "Cambiar foco";
                        }
                    } else if (actionRaw.includes("move")) {
                        let wsMatch = actionRaw.match(/workspace\s*=\s*([^}]+)/);
                        if (wsMatch) {
                            desc = "Mover ventana al espacio " + wsMatch[1].trim();
                        } else {
                            desc = "Mover ventana";
                        }
                    } else if (actionRaw.includes("workspace.toggle_special")) {
                        let spMatch = actionRaw.match(/"([^"]+)"/);
                        let name = spMatch ? spMatch[1] : "especial";
                        desc = "Alternar espacio especial: " + name;
                    } else if (actionRaw.includes("window.drag")) {
                        desc = "Arrastrar ventana";
                    } else if (actionRaw.includes("window.resize")) {
                        desc = "Redimensionar ventana";
                    }
                    desc = desc.charAt(0).toUpperCase() + desc.slice(1);
                    binds.push({ "keys": keys, "desc": desc });
                }
            }
        }
        binds.push({ "keys": "SUPER + [1-9]", "desc": "Enfocar espacio [1-9]" });
        binds.push({ "keys": "SUPER + SHIFT + [1-9]", "desc": "Mover ventana al espacio [1-9]" });
        return binds;
    }

    function saveNewBind() {
        let cleanKeys = newKeysInput.trim();
        let cleanCmd = newCmdInput.trim();
        let luaLine = '\nhl.bind("' + cleanKeys + '", hl.dsp.exec_cmd("' + cleanCmd + '"))\n';
        addBindProcess.command = ["python3", "-c", 'import os; path = os.path.expanduser("~/pro/dotfiles/hypr/modules/keybinds.lua"); open(path, "a").write(' + JSON.stringify(luaLine) + ')'];
        addBindProcess.running = true;
        showAddBind = false;
    }

    // Click outside to close (with dark overlay backdrop)
    MouseArea {
        anchors.fill: parent
        onClicked: settingsWindow.closePanel()

        Rectangle {
            anchors.fill: parent
            color: "#66000000" // 40% opacity black backdrop for focus
            opacity: settingsWindow.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // Main Card (Glassmorphic Caelestia Style - LARGER 720x460px)
    Rectangle {
        id: box
        width: 720
        height: 460
        radius: 24
        anchors.centerIn: parent
        
        // Translucent background to show compositor blur
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.75)
        
        // Beautiful glowing border using accent color
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
        border.width: 1.5
        clip: true

        // Exit / Entrance Animations
        opacity: settingsWindow.active ? 1 : 0
        scale: settingsWindow.active ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation { 
                duration: settingsWindow.active ? 280 : 180
                easing.type: settingsWindow.active ? Easing.OutBack : Easing.OutExpo 
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Row {
            anchors.fill: parent
            clip: true

            // 1. SIDEBAR (Left)
            Rectangle {
                id: sidebar
                width: 160
                height: parent.height
                color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.5)
                radius: 24

                // Cover right rounded corners of sidebar with a square overlay
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 24
                    color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.5)
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        width: parent.width
                        text: Theme.t.settings_title ?? "Ajustes"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        bottomPadding: 12
                        elide: Text.ElideRight
                    }

                    // Tab list (Pill design with gradients / nice colors)
                    Repeater {
                        model: [
                            { "name": Theme.t.wifi ?? "Wi-Fi", "icon": "\u{f05a9}" },
                            { "name": Theme.t.theme ?? "Tema", "icon": "\uf186" },
                            { "name": Theme.t.wallpaper ?? "Fondo", "icon": "\uf03e" },
                            { "name": Theme.t.keybinds ?? "Atajos", "icon": "\uf11c" },
                            { "name": Theme.t.language ?? "Lenguaje", "icon": "\uf1ab" }
                        ]

                        delegate: Rectangle {
                            width: parent.width
                            height: 36
                            radius: 18
                            
                            // Accent background for active pill, transparent for inactive
                            color: settingsWindow.activeSettingsTab === index ? Theme.accent : (tabMouse.containsMouse ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.3) : "transparent")

                            required property var modelData
                            required property int index

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    color: settingsWindow.activeSettingsTab === index ? Theme.bg : Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: settingsWindow.activeSettingsTab === index ? Theme.bg : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.bold: settingsWindow.activeSettingsTab === index
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsWindow.activeSettingsTab = index
                            }
                        }
                    }
                }
            }

            // Separation border
            Rectangle {
                width: 1
                height: parent.height
                color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
            }

            // 2. CONTENT AREA (Right)
            Rectangle {
                width: parent.width - sidebar.width - 1
                height: parent.height
                color: "transparent"

                // Padding/Margins around content (more breathing room)
                Item {
                    anchors.fill: parent
                    anchors.margins: 24

                    // Section 0: Wifi
                    Column {
                        anchors.fill: parent
                        visible: settingsWindow.activeSettingsTab === 0 && !settingsWindow.showAddBind
                        spacing: 16

                        Row {
                            width: parent.width
                            height: 28
                            spacing: 10

                            Text {
                                width: 22
                                anchors.verticalCenter: parent.verticalCenter
                                text: settingsWindow.wifiRadioActive ? "\u{f05a9}" : "\u{f05aa}"
                                color: settingsWindow.wifiRadioActive ? Theme.accent : Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                            }

                            Text {
                                width: parent.width - 22 - 36 - 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: Theme.t.wifi ?? "Wi-Fi"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Rectangle {
                                width: 38
                                height: 22
                                radius: 11
                                color: settingsWindow.wifiRadioActive ? Theme.accent : Theme.bgAlt
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    x: settingsWindow.wifiRadioActive ? 18 : 2
                                    y: 2
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: settingsWindow.wifiRadioActive ? Theme.bg : Theme.fgMuted

                                    Behavior on x {
                                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                    }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wifiToggleProcess.command = ["nmcli", "radio", "wifi", settingsWindow.wifiRadioActive ? "off" : "on"];
                                        wifiToggleProcess.running = true;
                                        settingsWindow.wifiRadioActive = !settingsWindow.wifiRadioActive;
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                        }

                        Text {
                            text: Theme.t.connect_to_net ?? "Conectar a una red:"
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            visible: settingsWindow.wifiRadioActive
                        }

                        ListView {
                            width: parent.width
                            height: parent.height - 76
                            visible: settingsWindow.wifiRadioActive
                            clip: true
                            spacing: 8
                            model: settingsWindow.wifiNetworks

                            delegate: Rectangle {
                                width: parent ? parent.width : 0
                                height: 36
                                radius: 10
                                
                                // Translucent item card
                                color: (wifiItemMouse.containsMouse || settingsWindow.connectingSSID === modelData.ssid) ? Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6) : "transparent"
                                border.color: (wifiItemMouse.containsMouse || settingsWindow.connectingSSID === modelData.ssid) ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : "transparent"
                                border.width: 1

                                required property var modelData

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "\u{f05a9}"
                                        color: settingsWindow.wifiSSID === modelData.ssid ? Theme.accent : Theme.fgMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        width: parent.width - 20 - 70
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ssid
                                        color: settingsWindow.wifiSSID === modelData.ssid ? Theme.accent : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        font.bold: settingsWindow.wifiSSID === modelData.ssid
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: 60
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: settingsWindow.connectingSSID === modelData.ssid ? "..." : (settingsWindow.wifiSSID === modelData.ssid ? (Theme.t.connected ?? "Ok") : modelData.signal + "%")
                                        color: settingsWindow.connectingSSID === modelData.ssid ? Theme.accent : Theme.fgMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                MouseArea {
                                    id: wifiItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (settingsWindow.connectingSSID === "" && settingsWindow.wifiSSID !== modelData.ssid) {
                                            settingsWindow.connectingSSID = modelData.ssid;
                                            settingsWindow.targetConnectSSID = modelData.ssid;
                                            wifiTryConnectProcess.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid];
                                            wifiTryConnectProcess.running = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Section 1: Tema (Dynamic Cards Grid with Colors Previews)
                    Column {
                        anchors.fill: parent
                        visible: settingsWindow.activeSettingsTab === 1 && !settingsWindow.showAddBind
                        spacing: 16

                        Text {
                            text: Theme.t.theme ?? "Tema"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Flow {
                            width: parent.width
                            spacing: 12

                            Repeater {
                                model: [
                                    { "id": "dark", "name": Theme.t.theme_dark ?? "Oscuro", "bg": "#242424", "accent": "#89b4fa", "fg": "#ffffff" },
                                    { "id": "light", "name": Theme.t.theme_light ?? "Claro", "bg": "#eff1f5", "accent": "#1e66f5", "fg": "#4c4f69" },
                                    { "id": "nord", "name": "Nord", "bg": "#2e3440", "accent": "#88c0d0", "fg": "#d8dee9" },
                                    { "id": "catppuccin", "name": "Catppuccin", "bg": "#1e1e2e", "accent": "#cba6f7", "fg": "#cdd6f4" },
                                    { "id": "rose_pine", "name": "Rose Pine", "bg": "#191724", "accent": "#ebbcba", "fg": "#e0def4" },
                                    { "id": "oled", "name": "OLED", "bg": "#000000", "accent": "#3abff8", "fg": "#ffffff" }
                                ]

                                delegate: Rectangle {
                                    width: (parent.width - 24) / 3 // Responsive grid
                                    height: 80
                                    radius: 14
                                    
                                    // Hex color binding
                                    color: Qt.rgba(parseInt(modelData.bg.substring(1,3), 16)/255.0, parseInt(modelData.bg.substring(3,5), 16)/255.0, parseInt(modelData.bg.substring(5,7), 16)/255.0, 0.65)

                                    // Border highlighting for active theme or hovered state
                                    border.color: (Theme.currentTheme === modelData.id) 
                                        ? Theme.accent 
                                        : (themeCardMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.3))
                                    border.width: (Theme.currentTheme === modelData.id) ? 2 : 1

                                    required property var modelData

                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text {
                                            text: modelData.name
                                            color: modelData.id === "light" ? "#4c4f69" : "#ffffff"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                        }

                                        Row {
                                            spacing: 8

                                            Rectangle {
                                                width: 14
                                                height: 14
                                                radius: 7
                                                color: modelData.bg
                                                border.color: "#888888"
                                                border.width: 0.5
                                            }

                                            Rectangle {
                                                width: 14
                                                height: 14
                                                radius: 7
                                                color: modelData.accent
                                            }

                                            Rectangle {
                                                width: 14
                                                height: 14
                                                radius: 7
                                                color: modelData.fg
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: themeCardMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            themeToggleProcess.command = [Quickshell.env("HOME") + "/pro/dotfiles/theme/apply-theme.sh", modelData.id];
                                            themeToggleProcess.running = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Section 2: Wallpaper (Visual Grid with Previews)
                    Column {
                        anchors.fill: parent
                        visible: settingsWindow.activeSettingsTab === 2
                        spacing: 12

                        Text {
                            text: Theme.t.wallpaper ?? "Fondo de Pantalla"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            text: (Theme.t.wallpaper_desc ?? "Selecciona una imagen de ") + settingsWindow.wallpaperDir
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                        }

                        ListView {
                            width: parent.width
                            height: parent.height - 60
                            clip: true
                            spacing: 8
                            model: settingsWindow.wallpapersList

                            delegate: Rectangle {
                                width: parent ? parent.width : 0
                                height: 80
                                radius: 12
                                color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                                border.color: (Theme.currentWallpaper === modelData.path) ? Theme.accent : (wallpaperMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2))
                                border.width: (Theme.currentWallpaper === modelData.path) ? 2 : 1
                                clip: true

                                required property var modelData

                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 12

                                    // Thumbnail preview
                                    Rectangle {
                                        width: 110
                                        height: 68
                                        radius: 8
                                        clip: true
                                        color: Theme.bg

                                        Image {
                                            anchors.fill: parent
                                            source: "file://" + modelData.path
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }
                                    }

                                    Column {
                                        width: parent.width - 122
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4

                                        Text {
                                            text: modelData.name
                                            color: (Theme.currentWallpaper === modelData.path) ? Theme.accent : Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: modelData.path.replace(Quickshell.env("HOME"), "~")
                                            color: Theme.fgMuted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            elide: Text.ElideMiddle
                                            width: parent.width
                                        }
                                    }
                                }

                                MouseArea {
                                    id: wallpaperMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        setWallpaperProcess.command = [Quickshell.env("HOME") + "/pro/dotfiles/theme/set-wallpaper.sh", modelData.path];
                                        setWallpaperProcess.running = true;
                                    }
                                }
                            }
                        }
                    }

                    // Section 3: Keybinds (Caelestia Style with Add Form)
                    Item {
                        anchors.fill: parent
                        visible: settingsWindow.activeSettingsTab === 3

                        // 1. Keybinds List & Header
                        Column {
                            anchors.fill: parent
                            spacing: 16
                            visible: !settingsWindow.showAddBind

                            Row {
                                width: parent.width
                                height: 28

                                Text {
                                    width: parent.width - 80
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (Theme.t.keybinds ?? "Atajos") + " (" + settingsWindow.keybindsList.length + ")"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                // Add Bind Button
                                Rectangle {
                                    width: 80
                                    height: 26
                                    radius: 13
                                    color: addBindMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
                                    border.color: addBindMouse.containsMouse ? "transparent" : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                                    border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+ " + (Theme.t.add_bind ?? "Agregar")
                                        color: addBindMouse.containsMouse ? Theme.bg : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: addBindMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            settingsWindow.newKeysInput = "";
                                            settingsWindow.newCmdInput = "";
                                            settingsWindow.showAddBind = true;
                                        }
                                    }
                                }
                            }

                            ListView {
                                width: parent.width
                                height: parent.height - 44
                                clip: true
                                spacing: 8
                                model: settingsWindow.keybindsList

                                delegate: Rectangle {
                                    width: parent ? parent.width : 0
                                    height: 52
                                    radius: 12
                                    
                                    // Translucent list item cards
                                    color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                                    border.color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2)
                                    border.width: 1

                                    required property var modelData

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 16

                                        // Left side: Description & Action/Command
                                        Column {
                                            width: parent.width - keysRow.implicitWidth - 16
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Text {
                                                width: parent.width
                                                text: modelData.desc
                                                color: Theme.fg
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 13
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                text: modelData.keys.includes("XF86") ? "Multimedia Key" : "Acción de sistema"
                                                color: Theme.fgMuted
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                            }
                                        }

                                        // Right side: Keyboard Key Pills (Caelestia Style)
                                        Row {
                                            id: keysRow
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4
                                            layoutDirection: Qt.RightToLeft

                                            Repeater {
                                                model: modelData.keys.split(" + ").reverse()

                                                delegate: Item {
                                                    id: keyPartDelegate
                                                    required property string modelData
                                                    required property int index

                                                    width: keyPill.width + (keyPartDelegate.index > 0 ? 12 : 0)
                                                    height: 24

                                                    Row {
                                                        spacing: 4
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        Text {
                                                            text: "+"
                                                            color: Theme.fgMuted
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            visible: keyPartDelegate.index > 0
                                                        }

                                                        Rectangle {
                                                            id: keyPill
                                                            width: keyText.implicitWidth + 14
                                                            height: 24
                                                            radius: 6
                                                            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.8)
                                                            border.color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.3)
                                                            border.width: 1

                                                            Text {
                                                                id: keyText
                                                                anchors.centerIn: parent
                                                                text: keyPartDelegate.modelData
                                                                color: Theme.accent
                                                                font.family: Theme.fontFamily
                                                                font.pixelSize: 12
                                                                font.bold: true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Add Bind Form
                        Column {
                            anchors.fill: parent
                            visible: settingsWindow.showAddBind
                            spacing: 16

                            Text {
                                text: "Agregar nuevo atajo"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Column {
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: "Combinación de teclas (ej: SUPER + SHIFT + A):"
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }

                                TextField {
                                    id: keysInputField
                                    width: parent.width
                                    text: settingsWindow.newKeysInput
                                    placeholderText: "SUPER + SHIFT + A"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    background: Rectangle {
                                        color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
                                        radius: 8
                                        border.color: keysInputField.activeFocus ? Theme.accent : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.3)
                                        border.width: 1
                                    }
                                    onTextChanged: settingsWindow.newKeysInput = text
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: "Comando o programa a ejecutar (ej: ghostty):"
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }

                                TextField {
                                    id: cmdInputField
                                    width: parent.width
                                    text: settingsWindow.newCmdInput
                                    placeholderText: "ghostty"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    background: Rectangle {
                                        color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
                                        radius: 8
                                        border.color: cmdInputField.activeFocus ? Theme.accent : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.3)
                                        border.width: 1
                                    }
                                    onTextChanged: settingsWindow.newCmdInput = text
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: 10
                                layoutDirection: Qt.RightToLeft

                                // Submit button
                                Rectangle {
                                    width: 90
                                    height: 32
                                    radius: 8
                                    color: (settingsWindow.newKeysInput.length > 0 && settingsWindow.newCmdInput.length > 0) ? (submitMouse.containsMouse ? Theme.accent : Qt.darker(Theme.accent, 1.1)) : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                                    border.color: (settingsWindow.newKeysInput.length > 0 && settingsWindow.newCmdInput.length > 0) ? "transparent" : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Guardar"
                                        color: (settingsWindow.newKeysInput.length > 0 && settingsWindow.newCmdInput.length > 0) ? Theme.bg : Theme.fgMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: submitMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: (settingsWindow.newKeysInput.length > 0 && settingsWindow.newCmdInput.length > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (settingsWindow.newKeysInput.length > 0 && settingsWindow.newCmdInput.length > 0) {
                                                settingsWindow.saveNewBind();
                                            }
                                        }
                                    }
                                }

                                // Cancel button
                                Rectangle {
                                    width: 90
                                    height: 32
                                    radius: 8
                                    color: cancelSubmitMouse.containsMouse ? Theme.surface : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                                    border.color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cancelar"
                                        color: Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: cancelSubmitMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: settingsWindow.showAddBind = false
                                    }
                                }
                            }
                        }
                    }

                    // Section 3: Lenguaje (Dynamic Grid & Form to Create Languages)
                    Item {
                        anchors.fill: parent
                        visible: settingsWindow.activeSettingsTab === 4

                        // 1. Language Cards Grid & Header
                        Column {
                            anchors.fill: parent
                            spacing: 12
                            visible: !settingsWindow.showAddLang

                            Row {
                                width: parent.width
                                height: 28

                                Text {
                                    width: parent.width - 80
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Theme.t.language ?? "Lenguaje"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                // Add Language Button
                                Rectangle {
                                    width: 80
                                    height: 26
                                    radius: 13
                                    color: addLangMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
                                    border.color: addLangMouse.containsMouse ? "transparent" : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                                    border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+ " + (Theme.t.add_lang ?? "Crear")
                                        color: addLangMouse.containsMouse ? Theme.bg : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: addLangMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            settingsWindow.newLangCode = "";
                                            settingsWindow.newLangName = "";
                                            settingsWindow.showAddLang = true;
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                            }

                            // Flow of languages
                            Flow {
                                width: parent.width
                                height: parent.height - 40
                                spacing: 12

                                Repeater {
                                    model: settingsWindow.languagesList

                                    delegate: Rectangle {
                                        width: (parent.width - 24) / 3 // 3 column grid
                                        height: 56
                                        radius: 12
                                        
                                        color: (Theme.currentLang === modelData.id) ? Theme.accent : (langCardMouse.containsMouse ? Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6) : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4))
                                        border.color: (Theme.currentLang === modelData.id) ? "transparent" : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2)
                                        border.width: 1

                                        required property var modelData

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 10

                                            // Styled language circle icon (e.g. ES, EN)
                                            Rectangle {
                                                width: 38
                                                height: 38
                                                radius: 19
                                                color: (Theme.currentLang === modelData.id) ? Theme.bg : Theme.surface
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.id.toUpperCase()
                                                    color: (Theme.currentLang === modelData.id) ? Theme.accent : Theme.fg
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }
                                            }

                                            Text {
                                                width: parent.width - 60
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.name
                                                color: (Theme.currentLang === modelData.id) ? Theme.bg : Theme.fg
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 13
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            id: langCardMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (Theme.currentLang !== modelData.id) {
                                                    langWriteProcess.command = ["python3", "-c", 'import json; import os; path = os.path.expanduser("~/pro/dotfiles/theme/current.json"); d = json.load(open(path)); d["lang"] = "' + modelData.id + '"; json.dump(d, open(path, "w"), indent=2)'];
                                                    langWriteProcess.running = true;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Add Language Form
                        Column {
                            anchors.fill: parent
                            visible: settingsWindow.showAddLang
                            spacing: 12

                            Text {
                                text: "Crear nuevo idioma"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: "Código de idioma (ej: fr, de, it):"
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }

                                TextField {
                                    id: langCodeInputField
                                    width: parent.width
                                    text: settingsWindow.newLangCode
                                    placeholderText: "fr"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    background: Rectangle {
                                        color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
                                        radius: 6
                                        border.color: langCodeInputField.activeFocus ? Theme.accent : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.3)
                                        border.width: 1
                                    }
                                    onTextChanged: settingsWindow.newLangCode = text.trim().toLowerCase()
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: "Nombre del idioma (ej: Français, Deutsch):"
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }

                                TextField {
                                    id: langNameInputField
                                    width: parent.width
                                    text: settingsWindow.newLangName
                                    placeholderText: "Français"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    background: Rectangle {
                                        color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
                                        radius: 6
                                        border.color: langNameInputField.activeFocus ? Theme.accent : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.3)
                                        border.width: 1
                                    }
                                    onTextChanged: settingsWindow.newLangName = text
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: 8
                                layoutDirection: Qt.RightToLeft

                                // Submit button
                                Rectangle {
                                    width: 80
                                    height: 28
                                    radius: 6
                                    color: (settingsWindow.newLangCode.length > 0 && settingsWindow.newLangName.length > 0) ? (langSubmitMouse.containsMouse ? Theme.accent : Qt.darker(Theme.accent, 1.1)) : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                                    border.color: (settingsWindow.newLangCode.length > 0 && settingsWindow.newLangName.length > 0) ? "transparent" : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Guardar"
                                        color: (settingsWindow.newLangCode.length > 0 && settingsWindow.newLangName.length > 0) ? Theme.bg : Theme.fgMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: langSubmitMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: (settingsWindow.newLangCode.length > 0 && settingsWindow.newLangName.length > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (settingsWindow.newLangCode.length > 0 && settingsWindow.newLangName.length > 0) {
                                                // Create new lang file and apply
                                                let pyCode = 'import json, os; d = os.path.expanduser("~/pro/dotfiles/lang"); t = json.load(open(os.path.join(d, "es.json"))); t["lang_name"] = ' + JSON.stringify(settingsWindow.newLangName) + '; json.dump(t, open(os.path.join(d, ' + JSON.stringify(settingsWindow.newLangCode) + ' + ".json"), "w"), indent=2, ensure_ascii=False); cur = json.load(open(os.path.join(d, "current.json"))); cur["lang"] = ' + JSON.stringify(settingsWindow.newLangCode) + '; json.dump(cur, open(os.path.join(d, "current.json"), "w"), indent=2)';
                                                createLangProcess.command = ["python3", "-c", pyCode];
                                                createLangProcess.running = true;
                                            }
                                        }
                                    }
                                }

                                // Cancel button
                                Rectangle {
                                    width: 80
                                    height: 28
                                    radius: 6
                                    color: langCancelMouse.containsMouse ? Theme.surface : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                                    border.color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cancelar"
                                        color: Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        id: langCancelMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: settingsWindow.showAddLang = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Settings Processes
    Process {
        id: wifiToggleProcess
    }

    Process {
        id: themeToggleProcess
    }

    Process {
        id: wifiConnectProcess
        onExited: (exitCode, exitStatus) => {
            settingsWindow.connectingSSID = "";
            netProcess.running = true;
        }
    }

    Process {
        id: wifiTryConnectProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // Connection failed directly, trigger the QML dialog
                if (settingsWindow.wifiPrompt) {
                    settingsWindow.wifiPrompt.askPassword(settingsWindow.targetConnectSSID, password => {
                        if (password !== null) {
                            settingsWindow.connectingSSID = settingsWindow.targetConnectSSID;
                            wifiConnectProcess.command = ["nmcli", "dev", "wifi", "connect", settingsWindow.targetConnectSSID, "password", password];
                            wifiConnectProcess.running = true;
                        } else {
                            settingsWindow.connectingSSID = "";
                        }
                    });
                } else {
                    settingsWindow.connectingSSID = "";
                }
                settingsWindow.closePanel();
            } else {
                settingsWindow.connectingSSID = "";
                netProcess.running = true;
            }
        }
    }

    Process {
        id: langWriteProcess
    }

    Process {
        id: addBindProcess
        onExited: (exitCode, exitStatus) => {
            hyprReloadProcess.running = true;
        }
    }

    Process {
        id: hyprReloadProcess
        command: ["hyprctl", "reload"]
    }

    Process {
        id: listLangsProcess
        command: ["python3", Quickshell.env("HOME") + "/pro/dotfiles/lang/list_langs.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    settingsWindow.languagesList = JSON.parse(data.trim());
                } catch(e) {
                    console.log("Error parsing languages: " + e);
                }
            }
        }
    }

    Process {
        id: createLangProcess
        onExited: (exitCode, exitStatus) => {
            listLangsProcess.running = true;
            settingsWindow.showAddLang = false;
        }
    }

    Process {
        id: listWallpapersProcess
        stdout: SplitParser {
            onRead: data => {
                try {
                    settingsWindow.wallpapersList = JSON.parse(data.trim());
                } catch(e) {
                    console.log("Error parsing wallpapers JSON: " + e);
                }
            }
        }
    }

    Process {
        id: setWallpaperProcess
    }
}
