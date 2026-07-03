import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "root:/theme"

Grid {
    id: root
    
    property bool isVertical: Theme.barPosition === "left" || Theme.barPosition === "right"
    
    spacing: 6
    columns: isVertical ? 1 : 99

    // Track default audio sink
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Properties for Network info
    property string netType: "none"
    property string wifiSSID: ""
    property string ipAddress: ""
    property string netInterface: ""
    property var wifiNetworks: []
    property string connectingSSID: ""

    // Properties for Popup Controls
    property bool volumeOpen: false
    property bool networkOpen: false
    property bool batteryOpen: false
    property bool settingsOpen: false
    property bool wifiRadioActive: false
    property bool wifiListExpanded: false
    property string targetConnectSSID: ""
    property var wifiPrompt: null
    property var settingsWindow: null

    // Network Polling
    Timer {
        id: netTimer
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netProcess.running = true;
        }
    }

    Process {
        id: netProcess
        command: ["sh", "-c", "default_iface=$(ip route show 2>/dev/null | grep default | awk '{print $5}' | head -n1); ip_addr=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}'); if [ -z \"$ip_addr\" ] && [ -n \"$default_iface\" ]; then ip_addr=$(ip -4 addr show dev \"$default_iface\" 2>/dev/null | grep 'inet' | head -n1 | awk '{print $2}' | cut -d/ -f1); fi; connection_type=\"none\"; ssid=\"\"; if [ -n \"$default_iface\" ]; then if [[ \"$default_iface\" =~ ^w ]]; then connection_type=\"wifi\"; ssid=$(iwgetid -r \"$default_iface\" 2>/dev/null || nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2); elif [[ \"$default_iface\" =~ ^e ]]; then connection_type=\"ethernet\"; fi; fi; wifi_radio=$(nmcli radio wifi 2>/dev/null || echo \"disabled\"); echo \"type:$connection_type|ssid:$ssid|ip:$ip_addr|iface:$default_iface|radio:$wifi_radio\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|");
                let type = "none";
                let ssid = "";
                let ip = "";
                let iface = "";
                let radio = "disabled";
                for (let part of parts) {
                    if (part.startsWith("type:")) type = part.substring(5);
                    else if (part.startsWith("ssid:")) ssid = part.substring(5);
                    else if (part.startsWith("ip:")) ip = part.substring(3);
                    else if (part.startsWith("iface:")) iface = part.substring(6);
                    else if (part.startsWith("radio:")) radio = part.substring(6);
                }
                root.netType = type;
                root.wifiSSID = ssid;
                root.ipAddress = ip;
                root.netInterface = iface;
                root.wifiRadioActive = (radio === "enabled");
            }
        }
    }

    // Wifi Networks Scan
    Timer {
        id: wifiScanTimer
        interval: 10000
        running: root.networkOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiScanProcess.running = true
    }

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
                root.wifiNetworks = networks;
            }
        }
    }

    // Helper functions
    function getVolumeIcon() {
        if (!Pipewire.defaultAudioSink) return "\uf026";
        if (Pipewire.defaultAudioSink.audio.muted) return "\uf6a9";
        let v = Pipewire.defaultAudioSink.audio.volume;
        if (v <= 0.0) return "\uf026";
        if (v < 0.33) return "\uf027";
        if (v < 0.66) return "\uf58f";
        return "\uf028";
    }

    function getNetworkIcon() {
        if (root.netType === "ethernet") return "\u{f0200}";
        if (root.netType === "wifi") return "\u{f05a9}";
        return "\u{f05aa}";
    }

    function getBatteryIcon() {
        if (!UPower.displayDevice) return "\uf240";
        let state = UPower.displayDevice.state;
        if (state === 1) return "\uf1e6"; // Charging
        let p = UPower.displayDevice.percentage;
        if (p >= 90) return "\uf240";
        if (p >= 65) return "\uf241";
        if (p >= 40) return "\uf242";
        if (p >= 15) return "\uf243";
        return "\uf244";
    }

    function formatBatteryTime(seconds) {
        if (seconds <= 0) return "";
        let hrs = Math.floor(seconds / 3600);
        let mins = Math.floor((seconds % 3600) / 60);
        if (hrs > 0) return hrs + "h " + mins + "m";
        return mins + "m";
    }

    // 1. VOLUME WIDGET
    Rectangle {
        id: volumeButton
        width: 24
        height: 24
        radius: 12
        color: root.volumeOpen ? Theme.accent : (volumeArea.containsMouse ? Theme.bgAlt : Theme.bg)

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: root.getVolumeIcon()
            color: root.volumeOpen ? Theme.bg : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        MouseArea {
            id: volumeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.volumeOpen = !root.volumeOpen;
                root.networkOpen = false;
                root.batteryOpen = false;
                root.settingsOpen = false;
            }
        }

        PopupWindow {
            id: volumePopup
            visible: root.volumeOpen || volClosingAnim.running

            property int gap: 20
            anchor.item: volumeButton
            anchor.edges: Theme.popupAnchorEdge
            anchor.gravity: Theme.popupAnchorGravity

            implicitWidth: 220
            implicitHeight: volumeCard.implicitHeight + gap
            color: "transparent"

            HyprlandFocusGrab {
                windows: [volumePopup]
                active: root.volumeOpen
                onCleared: root.volumeOpen = false
            }

            PropertyAnimation {
                id: volClosingAnim
                target: volumeCard
                property: "opacity"
                to: 0
                duration: 180
                easing.type: Easing.InCubic
            }

            Rectangle {
                id: volumeCard
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height - volumePopup.gap

                implicitWidth: 220
                implicitHeight: volumeLayout.implicitHeight + 24

                color: Theme.bg
                radius: 14
                border.color: Theme.bgAlt
                border.width: 1

                opacity: 0
                scale: 0.9
                y: 8

                states: State {
                    name: "open"
                    when: root.volumeOpen
                    PropertyChanges {
                        target: volumeCard
                        opacity: 1
                        scale: 1
                        y: 0
                    }
                }

                transitions: Transition {
                    NumberAnimation {
                        properties: "opacity,scale,y"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    id: volumeLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        width: parent.width
                        text: Theme.t.vol_title ?? "Audio - Volumen"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        height: 24
                        spacing: 8

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 6
                            color: muteMouse.containsMouse ? Theme.bgAlt : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted ? "\uf6a9" : "\uf028"
                                color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted ? Theme.red : Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: muteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Pipewire.defaultAudioSink) {
                                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                                    }
                                }
                            }
                        }

                        // Slider
                        Item {
                            id: volumeSlider
                            width: 116
                            height: 24

                            property real value: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0.0

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Theme.bgAlt
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                width: parent.width * volumeSlider.value
                                height: 6
                                radius: 3
                                color: Theme.accent
                            }

                            Rectangle {
                                x: (parent.width * volumeSlider.value) - (width / 2)
                                y: (parent.height - height) / 2
                                width: 12
                                height: 12
                                radius: 6
                                color: sliderMouse.containsMouse || sliderMouse.drag.active ? Theme.accent : Theme.fg
                                border.color: Theme.bg
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            MouseArea {
                                id: sliderMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                function updateValue(mouse) {
                                    let pos = Math.max(0, Math.min(mouse.x, width));
                                    let newValue = pos / width;
                                    if (Pipewire.defaultAudioSink) {
                                        Pipewire.defaultAudioSink.audio.volume = newValue;
                                    }
                                }

                                onPressed: mouse => updateValue(mouse)
                                onPositionChanged: mouse => {
                                    if (pressed) updateValue(mouse);
                                }
                            }
                        }

                        Text {
                            width: 32
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            text: Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : "0%"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.bgAlt
                    }

                    Text {
                        width: parent.width
                        text: Theme.t.output_device ?? "Dispositivo de Salida:"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: Pipewire.nodes

                            delegate: Rectangle {
                                id: deviceItem
                                required property var modelData

                                property bool isSinkDevice: modelData && modelData.isSink && !modelData.isStream
                                property bool isCurrent: isSinkDevice && Pipewire.defaultAudioSink === modelData

                                visible: isSinkDevice
                                width: parent.width
                                height: visible ? 20 : 0
                                radius: 4
                                color: isCurrent ? Theme.bgAlt : (deviceMouse.containsMouse ? Theme.surface : "transparent")

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "✓"
                                        color: Theme.accent
                                        font.pixelSize: 10
                                        visible: deviceItem.isCurrent
                                        width: visible ? 10 : 0
                                    }

                                    Text {
                                        width: parent.width - (deviceItem.isCurrent ? 16 : 0)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: deviceItem.modelData ? (deviceItem.modelData.description || deviceItem.modelData.name) : ""
                                        color: deviceItem.isCurrent ? Theme.accent : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: deviceMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Pipewire.preferredDefaultAudioSink = deviceItem.modelData;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            onVisibleChanged: {
                if (!root.volumeOpen && visible) {
                    volClosingAnim.start();
                }
            }
        }
    }

    // 2. NETWORK WIDGET
    Rectangle {
        id: networkButton
        width: 24
        height: 24
        radius: 12
        color: root.networkOpen ? Theme.accent : (networkArea.containsMouse ? Theme.bgAlt : Theme.bg)

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: root.getNetworkIcon()
            color: root.networkOpen ? Theme.bg : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        MouseArea {
            id: networkArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.networkOpen = !root.networkOpen;
                root.volumeOpen = false;
                root.batteryOpen = false;
                root.settingsOpen = false;
            }
        }

        PopupWindow {
            id: networkPopup
            visible: root.networkOpen || netClosingAnim.running

            property int gap: 20
            anchor.item: networkButton
            anchor.edges: Theme.popupAnchorEdge
            anchor.gravity: Theme.popupAnchorGravity

            implicitWidth: 240
            implicitHeight: networkCard.implicitHeight + gap
            color: "transparent"

            HyprlandFocusGrab {
                windows: [networkPopup]
                active: root.networkOpen
                onCleared: root.networkOpen = false
            }

            PropertyAnimation {
                id: netClosingAnim
                target: networkCard
                property: "opacity"
                to: 0
                duration: 180
                easing.type: Easing.InCubic
            }

            Rectangle {
                id: networkCard
                implicitWidth: 240
                implicitHeight: networkLayout.implicitHeight + 24

                Behavior on implicitHeight {
                    enabled: root.networkOpen
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height - networkPopup.gap

                color: Theme.bg
                radius: 14
                border.color: Theme.bgAlt
                border.width: 1

                opacity: 0
                scale: 0.9
                y: 8

                states: State {
                    name: "open"
                    when: root.networkOpen
                    PropertyChanges {
                        target: networkCard
                        opacity: 1
                        scale: 1
                        y: 0
                    }
                }

                transitions: Transition {
                    NumberAnimation {
                        properties: "opacity,scale,y"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    id: networkLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        width: parent.width
                        text: Theme.t.network ?? "Conexión de Red"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 8
                        
                        Text {
                            text: root.getNetworkIcon()
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        Column {
                            width: parent.width - 24
                            spacing: 2

                            Text {
                                text: root.netType === "wifi" ? "Wi-Fi: " + root.wifiSSID : (root.netType === "ethernet" ? "Cable (Ethernet)" : "Desconectado")
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.ipAddress !== "" ? "IP: " + root.ipAddress : "Sin dirección IP"
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                            }
                        }
                    }

                    // Wifi available networks
                    Column {
                        visible: root.netType === "wifi" && root.wifiNetworks.length > 0
                        width: parent.width
                        spacing: 4

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.bgAlt
                        }

                        Text {
                            text: "Redes disponibles:"
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Repeater {
                            model: root.wifiNetworks

                            delegate: Rectangle {
                                width: parent.width
                                height: 20
                                radius: 4
                                color: (wifiRowMouse.containsMouse || root.connectingSSID === modelData.ssid) ? Theme.bgAlt : "transparent"

                                required property var modelData

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "\u{f05a9}"
                                        color: root.wifiSSID === modelData.ssid ? Theme.accent : Theme.fgMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        width: parent.width - 24 - 60
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ssid
                                        color: root.wifiSSID === modelData.ssid ? Theme.accent : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: root.wifiSSID === modelData.ssid
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: 50
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.connectingSSID === modelData.ssid ? "Conectando..." : (root.wifiSSID === modelData.ssid ? "Conectado" : modelData.signal + "%")
                                        color: root.connectingSSID === modelData.ssid ? Theme.accent : Theme.fgMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                MouseArea {
                                    id: wifiRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.connectingSSID === "" && root.wifiSSID !== modelData.ssid) {
                                            root.connectingSSID = modelData.ssid;
                                            root.targetConnectSSID = modelData.ssid;
                                            wifiTryConnectProcess.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid];
                                            wifiTryConnectProcess.running = true;
                                         }
                                     }
                                 }
                            }
                        }
                    }
                }
            }

            onVisibleChanged: {
                if (!root.networkOpen && visible) {
                    netClosingAnim.start();
                }
            }
        }
    }

    // 3. BATTERY WIDGET (only visible if laptop battery is present)
    Rectangle {
        id: batteryButton
        visible: UPower.displayDevice && UPower.displayDevice.isPresent
        width: 24
        height: 24
        radius: 12
        color: root.batteryOpen ? Theme.accent : (batteryArea.containsMouse ? Theme.bgAlt : Theme.bg)

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: root.getBatteryIcon()
            color: root.batteryOpen ? Theme.bg : (UPower.displayDevice && UPower.displayDevice.percentage < 20 ? Theme.red : Theme.fg)
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        MouseArea {
            id: batteryArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.batteryOpen = !root.batteryOpen;
                root.volumeOpen = false;
                root.networkOpen = false;
                root.settingsOpen = false;
            }
        }

        PopupWindow {
            id: batteryPopup
            visible: root.batteryOpen || batClosingAnim.running

            property int gap: 20
            anchor.item: batteryButton
            anchor.edges: Theme.popupAnchorEdge
            anchor.gravity: Theme.popupAnchorGravity

            implicitWidth: 200
            implicitHeight: 94 + gap
            color: "transparent"

            HyprlandFocusGrab {
                windows: [batteryPopup]
                active: root.batteryOpen
                onCleared: root.batteryOpen = false
            }

            PropertyAnimation {
                id: batClosingAnim
                target: batteryCard
                property: "opacity"
                to: 0
                duration: 180
                easing.type: Easing.InCubic
            }

            Rectangle {
                id: batteryCard
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height - batteryPopup.gap

                color: Theme.bg
                radius: 14
                border.color: Theme.bgAlt
                border.width: 1

                opacity: 0
                scale: 0.9
                y: 8

                states: State {
                    name: "open"
                    when: root.batteryOpen
                    PropertyChanges {
                        target: batteryCard
                        opacity: 1
                        scale: 1
                        y: 0
                    }
                }

                transitions: Transition {
                    NumberAnimation {
                        properties: "opacity,scale,y"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        width: parent.width
                        text: "Estado de Energía"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: root.getBatteryIcon()
                            color: UPower.displayDevice && UPower.displayDevice.state === 1 ? Theme.green : (UPower.displayDevice && UPower.displayDevice.percentage < 20 ? Theme.red : Theme.accent)
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        Column {
                            spacing: 2

                            Text {
                                text: UPower.displayDevice ? (Theme.t.battery ?? "Batería") + ": " + Math.round(UPower.displayDevice.percentage) + "%" : (Theme.t.battery_not_found ?? "No detectada")
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: {
                                    if (!UPower.displayDevice) return "";
                                    let state = UPower.displayDevice.state;
                                    if (state === 1) return (Theme.t.charging ?? "Cargando") + " (Full " + (Theme.t.in ?? "en") + " " + root.formatBatteryTime(UPower.displayDevice.timeToFull) + ")";
                                    if (state === 2) return (Theme.t.discharging ?? "Descargando") + " (" + root.formatBatteryTime(UPower.displayDevice.timeToEmpty) + " " + (Theme.t.remaining ?? "restante") + ")";
                                    if (state === 4) return Theme.t.full ?? "Totalmente cargada";
                                    return UPowerDeviceState.toString(state);
                                }
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: UPower.displayDevice && UPower.displayDevice.changeRate !== 0 ? (Theme.t.consumption ?? "Consumo") + ": " + Math.abs(UPower.displayDevice.changeRate).toFixed(1) + " W" : ""
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                }
            }

            onVisibleChanged: {
                if (!root.batteryOpen && visible) {
                    batClosingAnim.start();
                }
            }
        }
    }

    // 4. SETTINGS WIDGET
    Rectangle {
        id: settingsButton
        width: 24
        height: 24
        radius: 12
        color: (root.settingsWindow && root.settingsWindow.visible) ? Theme.accent : (settingsArea.containsMouse ? Theme.bgAlt : Theme.bg)

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "\uf013"
            color: (root.settingsWindow && root.settingsWindow.visible) ? Theme.bg : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        MouseArea {
            id: settingsArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.settingsWindow) {
                    if (typeof root.settingsWindow.toggle === "function") {
                        root.settingsWindow.toggle();
                    } else {
                        root.settingsWindow.visible = !root.settingsWindow.visible;
                    }
                }
                root.volumeOpen = false;
                root.networkOpen = false;
                root.batteryOpen = false;
            }
        }
    }

    // WiFi Connection Processes
    Process {
        id: wifiConnectProcess
        onExited: (exitCode, exitStatus) => {
            root.connectingSSID = "";
            netProcess.running = true;
        }
    }

    Process {
        id: wifiTryConnectProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                if (root.wifiPrompt) {
                    root.wifiPrompt.askPassword(root.targetConnectSSID, password => {
                        if (password !== null) {
                            root.connectingSSID = root.targetConnectSSID;
                            wifiConnectProcess.command = ["nmcli", "dev", "wifi", "connect", root.targetConnectSSID, "password", password];
                            wifiConnectProcess.running = true;
                        } else {
                            root.connectingSSID = "";
                        }
                    });
                } else {
                    root.connectingSSID = "";
                }
            } else {
                root.connectingSSID = "";
                netProcess.running = true;
            }
        }
    }
}
