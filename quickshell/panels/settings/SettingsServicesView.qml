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
        spacing: 16

        // 1. Wifi Toggle Row (Redesigned as an Item to prevent Row alignment bugs!)
        Item {
            width: parent.width
            height: 35

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    text: "📶"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: settingsWindow && settingsWindow.wifiRadioActive ? Theme.accent : Theme.fgMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: Theme.currentLang === "es" ? "Red Wi-Fi" : "Wi-Fi Network"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
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
                color: settingsWindow && settingsWindow.wifiRadioActive ? Theme.accent : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                border.color: settingsWindow && settingsWindow.wifiRadioActive ? "transparent" : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: settingsWindow && settingsWindow.wifiRadioActive ? Theme.bg : Theme.fgMuted
                    x: settingsWindow && settingsWindow.wifiRadioActive ? 20 : 2
                    y: 1

                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
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

        // 2. Wifi Networks List Container
        Rectangle {
            width: parent.width
            height: parent.height - 55 // Remaining height
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.25)
            radius: 12
            border.color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.1)
            clip: true

            Text {
                visible: settingsWindow && !settingsWindow.wifiRadioActive
                anchors.centerIn: parent
                text: Theme.currentLang === "es" ? "Wi-Fi desactivado" : "Wi-Fi disabled"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.fgMuted
            }

            ListView {
                visible: settingsWindow && settingsWindow.wifiRadioActive
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                model: settingsWindow ? settingsWindow.wifiNetworks : []

                delegate: Rectangle {
                    id: wifiDelegate
                    required property var modelData
                    width: parent.width
                    height: 42
                    radius: 8
                    color: (wifiItemMouse.containsMouse || (settingsWindow && settingsWindow.connectingSSID === modelData.ssid)) ? Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.15)
                    border.color: (wifiItemMouse.containsMouse || (settingsWindow && settingsWindow.connectingSSID === modelData.ssid)) ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : "transparent"
                    border.width: 1

                    // 1. Icon (left aligned)
                    Text {
                        id: wifiIcon
                        text: (settingsWindow && settingsWindow.wifiSSID === modelData.ssid) ? "★" : "⚡"
                        color: (settingsWindow && settingsWindow.wifiSSID === modelData.ssid) ? Theme.accent : Theme.fgMuted
                        font.pixelSize: 13
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // 2. Info Column (anchored relative to icon to prevent overlap)
                    Column {
                        id: wifiInfoCol
                        anchors.left: wifiIcon.right
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: wifiSignalText.left
                        anchors.rightMargin: 12
                        spacing: 2

                        Text {
                            text: modelData.ssid === "" ? "[Oculta / Hidden]" : modelData.ssid
                            color: (settingsWindow && settingsWindow.wifiSSID === modelData.ssid) ? Theme.accent : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: settingsWindow && settingsWindow.wifiSSID === modelData.ssid
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.security === "" ? "Open" : modelData.security
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    // 3. Status/Signal Percentage (right aligned)
                    Text {
                        id: wifiSignalText
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: (settingsWindow && settingsWindow.connectingSSID === modelData.ssid) ? "..." : ((settingsWindow && settingsWindow.wifiSSID === modelData.ssid) ? "OK" : modelData.signal + "%")
                        color: (settingsWindow && settingsWindow.connectingSSID === modelData.ssid) ? Theme.accent : Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
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
