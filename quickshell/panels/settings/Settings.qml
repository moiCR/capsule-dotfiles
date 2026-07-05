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
    property string wallpapersBuffer: ""
    property string wallpaperDir: { let home = Quickshell.env("HOME"); return Theme.currentLang === "es" ? home + "/Imágenes/Wallpapers" : home + "/Pictures/Wallpapers"; }

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

    // Main Card (Glassmorphic Capsule/Dock Style - LARGER 780x480px)
    Rectangle {
        id: box

        // Target dimensions
        readonly property int targetWidth: 780
        readonly property int targetHeight: 480
        readonly property int targetRadius: 24

        // Centered coordinates on screen
        readonly property real centerX: (parent.width - targetWidth) / 2
        readonly property real centerY: (parent.height - targetHeight) / 2

        // Start position (dock position: top center)
        readonly property real startX: (parent.width - 48) / 2
        readonly property real startY: 12

        // Current animating dimensions and position
        width: targetWidth
        height: targetHeight
        radius: targetRadius
        x: centerX
        y: centerY

        // Dark translucent glassmorphic look
        color: Qt.rgba(0.06, 0.05, 0.05, 0.88)
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
        border.width: 1.5
        clip: true

        states: [
            State {
                name: "closed"
                when: !settingsWindow.active
                PropertyChanges {
                    target: box
                    width: 48
                    height: 48
                    radius: 24
                    x: box.startX
                    y: box.startY
                    opacity: 0
                }
            },
            State {
                name: "open"
                when: settingsWindow.active
                PropertyChanges {
                    target: box
                    width: box.targetWidth
                    height: box.targetHeight
                    radius: box.targetRadius
                    x: box.centerX
                    y: box.centerY
                    opacity: 1
                }
            }
        ]

        transitions: [
            Transition {
                from: "closed"
                to: "open"
                ParallelAnimation {
                    NumberAnimation {
                        properties: "x,y,width,height"
                        duration: 380
                        easing.type: Easing.OutBack
                        easing.amplitude: 0.8
                    }
                    NumberAnimation {
                        property: "radius"
                        duration: 380
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        property: "opacity"
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            },
            Transition {
                from: "open"
                to: "closed"
                ParallelAnimation {
                    NumberAnimation {
                        properties: "x,y,width,height"
                        duration: 220
                        easing.type: Easing.InBack
                    }
                    NumberAnimation {
                        property: "radius"
                        duration: 220
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        property: "opacity"
                        duration: 200
                        easing.type: Easing.InQuad
                    }
                }
            }
        ]

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Item {
            id: cardContent
            anchors.fill: parent
            opacity: (box.width > box.targetWidth - 50) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // 1. Header (Top Title and Close)
            Item {
                id: header
                width: parent.width
                height: 44
                anchors.top: parent.top

                Text {
                    text: Theme.currentLang === "es" ? "Ajustes" : "Settings"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    anchors.centerIn: parent
                }

                Text {
                    text: "✕"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: closeMouse.containsMouse ? Theme.red : Theme.fgMuted
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWindow.closePanel()
                    }
                }
            }

            // Horizontal Separator below header
            Rectangle {
                id: headerDivider
                width: parent.width
                height: 1
                color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                anchors.top: header.bottom
            }

            // 2. Main Row containing Sidebar and View Loader
            Row {
                anchors.top: headerDivider.bottom
                anchors.bottom: parent.bottom
                width: parent.width

                SettingsSidebar {
                    id: sidebar
                    activeTab: settingsWindow.activeSettingsTab
                    settingsWindow: settingsWindow
                }

                // Vertical Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                }

                // View Page Container
                Item {
                    width: parent.width - 181
                    height: parent.height
                    clip: true

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 20
                        source: {
                            switch(settingsWindow.activeSettingsTab) {
                                case 0: return "SettingsStyleView.qml";
                                case 1: return "SettingsInterfaceView.qml";
                                case 2: return "SettingsServicesView.qml";
                                default: return "";
                            }
                        }
                        onLoaded: {
                            if (item) {
                                item.settingsWindow = settingsWindow;
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

    property var listLangsProcess: listLangsProcess
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
                settingsWindow.wallpapersBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            try {
                settingsWindow.wallpapersList = JSON.parse(settingsWindow.wallpapersBuffer.trim());
            } catch(e) {
                console.log("Error parsing wallpapers: " + e + "\nBuffer length: " + settingsWindow.wallpapersBuffer.length);
            }
            settingsWindow.wallpapersBuffer = "";
        }
    }

    Process {
        id: setWallpaperProcess
    }

    Process {
        id: setBarPosProcess
    }
}
