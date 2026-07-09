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
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

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

    // Expose processes as properties for sub-views
    property alias wifiToggleProcess: wifiToggleProcess
    property alias themeToggleProcess: themeToggleProcess
    property alias wifiConnectProcess: wifiConnectProcess
    property alias wifiTryConnectProcess: wifiTryConnectProcess
    property alias langWriteProcess: langWriteProcess
    property alias hyprReloadProcess: hyprReloadProcess
    property alias setWallpaperProcess: setWallpaperProcess
    property alias setBarPosProcess: setBarPosProcess

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
        resetSubmapProcess.running = true;
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
                let startIdx = line.indexOf("hl.bind(") + 8;
                let commaIdx = line.indexOf(",", startIdx);
                if (commaIdx !== -1) {
                    let keysRaw = line.substring(startIdx, commaIdx).trim();
                    let rest = line.substring(commaIdx + 1).trim();
                    
                    let actionRaw = "";
                    if (rest.endsWith("})")) {
                        let lastBrace = rest.lastIndexOf("{");
                        let optionsComma = rest.lastIndexOf(",", lastBrace);
                        if (optionsComma !== -1) {
                            actionRaw = rest.substring(0, optionsComma).trim();
                        } else {
                            actionRaw = rest.trim();
                        }
                    } else if (rest.endsWith(")")) {
                        actionRaw = rest.substring(0, rest.length - 1).trim();
                    } else {
                        actionRaw = rest.trim();
                    }

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
                    let rawCmd = actionRaw;
                    if (actionRaw.includes("exec_cmd")) {
                        let cmdMatch = actionRaw.match(/exec_cmd\(([^)]+)\)/);
                        if (cmdMatch) {
                            let matchStr = cmdMatch[1].trim();
                            if ((matchStr.startsWith('"') && matchStr.endsWith('"')) || 
                                (matchStr.startsWith("'") && matchStr.endsWith("'"))) {
                                rawCmd = matchStr.slice(1, -1);
                            } else {
                                rawCmd = matchStr;
                            }
                        }
                    }
                    desc = desc.charAt(0).toUpperCase() + desc.slice(1);
                    binds.push({ "keys": keys, "desc": desc, "cmd": rawCmd });
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
        hoverEnabled: false
        onClicked: settingsWindow.closePanel()

        Rectangle {
            anchors.fill: parent
            color: "#0c0d12"
            opacity: settingsWindow.active ? 0.6 : 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        }
    }

    // Main Card (Solid Capsule Style - 820x520px)
    Rectangle {
        id: box

        // Target dimensions
        readonly property int targetWidth: 820
        readonly property int targetHeight: 520
        readonly property int targetRadius: 24

        // Centered coordinates on screen
        readonly property real centerX: (Screen.width - targetWidth) / 2
        readonly property real centerY: (Screen.height - targetHeight) / 2

        // Start position (dock position: top center)
        readonly property real startX: (Screen.width - 48) / 2
        readonly property real startY: 12

        // Current animating dimensions and position
        width: targetWidth
        height: targetHeight
        radius: targetRadius
        x: centerX
        y: centerY

        // Solid background matching the Capsule design
        color: Theme.bg
        border.color: Theme.bgAlt
        border.width: 1
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
                height: 54
                anchors.top: parent.top

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: "\uf013" // Gear icon
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: Theme.currentLang === "es" ? "Ajustes de Sistema" : "System Settings"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Beautiful circular close button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15) : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.red : "transparent"
                    border.width: 1
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        text: "\uf00d" // Close icon
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: closeMouse.containsMouse ? Theme.red : Theme.fgMuted
                        anchors.centerIn: parent
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
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
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
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
                    height: parent.height
                }

                // Vertical Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                }

                // View Page Container
                Item {
                    width: parent.width - sidebar.width - 1
                    height: parent.height
                    clip: true

                    Loader {
                        id: viewLoader
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.top: parent.top
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        anchors.bottomMargin: 20
                        anchors.topMargin: 20
                        opacity: 0
                        source: {
                            switch(settingsWindow.activeSettingsTab) {
                                case 0: return "SettingsStyleView.qml";
                                case 1: return "SettingsInterfaceView.qml";
                                case 2: return "SettingsServicesView.qml";
                                case 3: return "SettingsMonitorsView.qml";
                                case 4: return "SettingsInputView.qml";
                                default: return "";
                            }
                        }
                        onLoaded: {
                            if (item) {
                                item.settingsWindow = settingsWindow;
                            }
                            fadeInAnimation.restart();
                        }
                    }

                    ParallelAnimation {
                        id: fadeInAnimation
                        NumberAnimation { target: viewLoader; property: "opacity"; from: 0.0; to: 1.0; duration: 220; easing.type: Easing.OutQuad }
                        NumberAnimation { target: viewLoader; property: "anchors.topMargin"; from: 35; to: 20; duration: 250; easing.type: Easing.OutCubic }
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

    Process {
        id: resetSubmapProcess
        command: ["hyprctl", "eval", "hl.dispatch(hl.dsp.submap(\"reset\"))"]
    }
}
