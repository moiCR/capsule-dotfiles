import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell
import Quickshell.Io

Item {
    id: sidebarRoot
    width: 200
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
        spacing: 16

        // 1. User / Profile Card
        Row {
            width: parent.width
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            // Avatar circle with dynamic gradient
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accent }
                        GradientStop { position: 1.0; color: Qt.darker(Theme.accent, 1.4) }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf007" // User icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    color: Theme.bg
                    font.bold: true
                }
            }

            // User Info
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "Moi"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.fg
                }
                Text {
                    text: Theme.currentLang === "es" ? "Administrador" : "Administrator"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    color: Theme.fgMuted
                }
            }
        }

        // Horizontal Separator below profile card
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
        }

        // 2. Navigation Tabs List
        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: [
                    { "icon": "\uf1fc", "name": Theme.currentLang === "es" ? "Estilo" : "Style" },
                    { "icon": "\uf11c", "name": Theme.currentLang === "es" ? "Interfaz" : "Interface" },
                    { "icon": "\uf085", "name": Theme.currentLang === "es" ? "Servicios" : "Services" }
                ]

                delegate: Rectangle {
                    id: tabItem
                    width: parent.width
                    height: 38
                    radius: 10
                    
                    // Smooth transition color
                    color: activeTab === index 
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                        : (tabMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05) : "transparent")
                    
                    border.color: activeTab === index 
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                        : (tabMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Left Indicator Pill
                    Rectangle {
                        width: 3
                        height: activeTab === index ? 16 : 0
                        radius: 1.5
                        color: Theme.accent
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            text: modelData.icon
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: activeTab === index ? Theme.accent : Theme.fgMuted
                        }

                        Text {
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: activeTab === index
                            color: activeTab === index ? Theme.accent : Theme.fg
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (settingsWindow) {
                                settingsWindow.activeSettingsTab = index;
                            }
                        }
                    }
                }
            }
        }

        // Spacer to push edit config button to the bottom
        Item {
            width: 1
            height: sidebarRoot.height - 16 - 16 - 38 - 1 - 16 - (3 * 38 + 2 * 6) - 50 - 32
        }

        // 3. Edit Config Button at the bottom
        Rectangle {
            width: parent.width
            height: 38
            radius: 10
            color: editMouse.containsMouse 
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08) 
                : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02)
            border.color: editMouse.containsMouse 
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) 
                : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "\uf044" // Edit icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: editMouse.containsMouse ? Theme.accent : Theme.fgMuted
                }
                Text {
                    text: Theme.currentLang === "es" ? "Configuración" : "Dotfiles"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: editMouse.containsMouse ? Theme.accent : Theme.fg
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
    }
}
