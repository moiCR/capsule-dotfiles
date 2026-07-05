import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell

Item {
    id: aboutViewRoot
    anchors.fill: parent

    property var settingsWindow: null

    Row {
        anchors.fill: parent
        spacing: 24

        // Left Side: Brand Logo / Icon
        Column {
            width: 140
            spacing: 12
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: 100
                height: 100
                radius: 50
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                border.color: Theme.accent
                border.width: 2
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: "❄"
                    font.pixelSize: 48
                    color: Theme.accent
                }
            }

            Text {
                text: "Antigravity OS"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "v2.0-Caelestia"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Vertical Separator
        Rectangle {
            width: 1
            height: parent.height - 40
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
            anchors.verticalCenter: parent.verticalCenter
        }

        // Right Side: System Properties
        Column {
            width: parent.width - 165
            spacing: 14
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: Theme.currentLang === "es" ? "Información del Sistema" : "System Information"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Grid {
                columns: 2
                spacing: 10
                width: parent.width

                Repeater {
                    model: [
                        { "k": Theme.currentLang === "es" ? "Equipo" : "Host", "v": "Antigravity-WM" },
                        { "k": "OS", "v": "Arch Linux" },
                        { "k": "Compositor", "v": "Hyprland (Wayland)" },
                        { "k": "Shell UI", "v": "Quickshell + Qt 6" },
                        { "k": "Tema Activo", "v": Theme.currentTheme },
                        { "k": "Usuario", "v": "moi" }
                    ]

                    delegate: Row {
                        width: 140
                        spacing: 8
                        Text {
                            text: modelData.k + ":"
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            width: 80
                        }
                        Text {
                            text: modelData.v
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            // Simple system description message
            Text {
                width: parent.width
                text: Theme.currentLang === "es" 
                    ? "Interfaz y panel de control modernizados con diseño de vidrio translúcido y acoplamiento elástico de cápsula." 
                    : "Modernized interface and control panel with translucent glass design and elastic capsule docking."
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }
}
