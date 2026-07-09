import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell
import Quickshell.Io

Item {
    id: servicesViewRoot
    anchors.fill: parent

    property var settingsWindow: null

    Process {
        id: wifiToggleProcess
    }

    Process {
        id: wifiConnectProcess
        onExited: (exitCode, exitStatus) => {
            if (settingsWindow) {
                settingsWindow.connectingSSID = "";
                settingsWindow.netProcess.running = true;
            }
        }
    }

    Process {
        id: wifiTryConnectProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                if (settingsWindow && settingsWindow.wifiPrompt) {
                    settingsWindow.wifiPrompt.askPassword(settingsWindow.targetConnectSSID, password => {
                        if (password !== null) {
                            settingsWindow.connectingSSID = settingsWindow.targetConnectSSID;
                            wifiConnectProcess.command = ["nmcli", "dev", "wifi", "connect", settingsWindow.targetConnectSSID, "password", password];
                            wifiConnectProcess.running = true;
                        } else {
                            settingsWindow.connectingSSID = "";
                        }
                    });
                } else if (settingsWindow) {
                    settingsWindow.connectingSSID = "";
                }
            } else if (settingsWindow) {
                settingsWindow.connectingSSID = "";
                settingsWindow.netProcess.running = true;
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 20

        // 1. Wifi Toggle Row
        Item {
            width: parent.width
            height: 32

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    text: "\uf1eb" // Wifi icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: settingsWindow && settingsWindow.wifiRadioActive ? Theme.accent : Theme.fgMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: Theme.currentLang === "es" ? "Red Wi-Fi" : "Wi-Fi Network"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // iOS-style Toggle Switch
            Rectangle {
                id: switchBg
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 20
                radius: 10
                color: settingsWindow && settingsWindow.wifiRadioActive ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                border.color: settingsWindow && settingsWindow.wifiRadioActive ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: settingsWindow && settingsWindow.wifiRadioActive ? Theme.bg : Theme.fgMuted
                    x: settingsWindow && settingsWindow.wifiRadioActive ? 22 : 3
                    y: 2

                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (settingsWindow) {
                            wifiToggleProcess.command = ["nmcli", "radio", "wifi", settingsWindow.wifiRadioActive ? "off" : "on"];
                            wifiToggleProcess.running = true;
                            settingsWindow.wifiRadioActive = !settingsWindow.wifiRadioActive;
                        }
                    }
                }
            }
        }

        // 2. Wifi Networks List Container (Glassmorphic card container)
        Rectangle {
            width: parent.width
            height: parent.height - 52 // Remaining height
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02)
            radius: 12
            border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
            border.width: 1
            clip: true

            Text {
                visible: settingsWindow && !settingsWindow.wifiRadioActive
                anchors.centerIn: parent
                text: Theme.currentLang === "es" ? "Wi-Fi desactivado" : "Wi-Fi disabled"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fgMuted
            }

            ListView {
                id: wifiListView
                visible: settingsWindow && settingsWindow.wifiRadioActive
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                model: settingsWindow ? settingsWindow.wifiNetworks : []

                delegate: Rectangle {
                    id: wifiDelegate
                    required property var modelData
                    width: ListView.view.width
                    height: 44
                    radius: 8
                    
                    color: (wifiItemMouse.containsMouse || (settingsWindow && settingsWindow.connectingSSID === modelData.ssid)) 
                        ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04) 
                        : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.01)
                    border.color: (settingsWindow && settingsWindow.wifiSSID === modelData.ssid)
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                        : ((wifiItemMouse.containsMouse || (settingsWindow && settingsWindow.connectingSSID === modelData.ssid)) ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1) : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    // 1. Connection status icon (left aligned)
                    Text {
                        id: wifiIcon
                        text: (settingsWindow && settingsWindow.wifiSSID === modelData.ssid) ? "\uf1eb" : "\uf023" // lock icon if not connected, or wifi if active
                        color: (settingsWindow && settingsWindow.wifiSSID === modelData.ssid) ? Theme.accent : Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // 2. Info Column
                    Column {
                        id: wifiInfoCol
                        anchors.left: wifiIcon.right
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: signalIndicator.left
                        anchors.rightMargin: 12
                        spacing: 2

                        Text {
                            text: modelData.ssid === "" ? (Theme.currentLang === "es" ? "[Red Oculta]" : "[Hidden Network]") : modelData.ssid
                            color: (settingsWindow && settingsWindow.wifiSSID === modelData.ssid) ? Theme.accent : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: settingsWindow && settingsWindow.wifiSSID === modelData.ssid
                            elide: Text.ElideRight
                        }
                        Text {
                            text: (settingsWindow && settingsWindow.wifiSSID === modelData.ssid) 
                                ? (Theme.currentLang === "es" ? "Conectado" : "Connected")
                                : (settingsWindow && settingsWindow.connectingSSID === modelData.ssid 
                                    ? (Theme.currentLang === "es" ? "Conectando..." : "Connecting...")
                                    : (Theme.currentLang === "es" ? "Disponible" : "Available"))
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                        }
                    }

                    // 3. Dynamic Signal Bars Indicator (Right aligned)
                    Row {
                        id: signalIndicator
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        
                        // Hide signal bars if connecting, show text status instead
                        visible: !(settingsWindow && settingsWindow.connectingSSID === modelData.ssid)

                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                width: 3
                                height: (index + 1) * 3
                                radius: 1
                                color: modelData.signal >= (index + 1) * 25 
                                    ? ((settingsWindow && settingsWindow.wifiSSID === modelData.ssid) ? Theme.accent : Theme.fg)
                                    : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)
                            }
                        }
                    }

                    // Connecting indicator (Text "..." when connecting)
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "..."
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        visible: settingsWindow && settingsWindow.connectingSSID === modelData.ssid
                    }

                    MouseArea {
                        id: wifiItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (settingsWindow && settingsWindow.connectingSSID === "" && settingsWindow.wifiSSID !== modelData.ssid) {
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
    }
}
