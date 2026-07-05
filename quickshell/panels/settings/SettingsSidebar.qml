import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell
import Quickshell.Io

Item {
    id: sidebarRoot
    width: 180
    height: parent.height

    property int activeTab: 0
    property var settingsWindow: null

    Process {
        id: editConfigProcess
        command: ["xdg-open", Quickshell.env("HOME") + "/pro/dotfiles"]
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        // 1. Top Logo/Burger Icon Row
        Row {
            spacing: 12
            width: parent.width

            Text {
                text: "☰"
                font.family: Theme.fontFamily
                font.pixelSize: 18
                color: Theme.fg
                font.bold: true
            }
        }

        // 2. Large Edit Config button
        Rectangle {
            width: parent.width
            height: 40
            radius: 12
            color: editMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "✏"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: Theme.accent
                }
                Text {
                    text: Theme.currentLang === "es" ? "Editar Config" : "Edit Config"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.accent
                }
            }

            MouseArea {
                id: editMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: editConfigProcess.running = true
            }
        }

        // Spacer
        Item { width: 1; height: 10 }

        // 3. Navigation Tabs List
        Column {
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { "icon": "🎨", "name": Theme.currentLang === "es" ? "Estilo" : "Style" },
                    { "icon": "⌨", "name": Theme.currentLang === "es" ? "Interfaz" : "Interface" },
                    { "icon": "⚙", "name": Theme.currentLang === "es" ? "Servicios" : "Services" }
                ]

                delegate: Rectangle {
                    width: parent.width
                    height: 38
                    radius: 19 // Capsule style
                    color: activeTab === index ? Theme.accent : (tabMouse.containsMouse ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.15) : "transparent")
                    border.color: activeTab === index ? "transparent" : (tabMouse.containsMouse ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.1) : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            text: modelData.icon
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: activeTab === index ? Theme.bg : Theme.fgMuted
                        }

                        Text {
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: activeTab === index
                            color: activeTab === index ? Theme.bg : Theme.fg
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            activeTab = index;
                            if (settingsWindow) {
                                settingsWindow.activeSettingsTab = index;
                            }
                        }
                    }
                }
            }
        }
    }
}
