import QtQuick
import Quickshell
import Quickshell.Io
import "root:/theme"

Item {
    id: themeWrapper

    readonly property int cardWidth: 122
    readonly property int cardHeight: 74
    readonly property int pad: 16

    implicitWidth: 3 * cardWidth + 2 * 10 + pad * 2   // = 388 + 32 = 420 → matches dock state
    implicitHeight: 2 * cardHeight + 10 + 20 + 12 + 1 + 12 + pad

    focus: true
    Component.onCompleted: themeWrapper.forceActiveFocus()
    Keys.onEscapePressed: dock.currentMode = "default"

    readonly property var themes: [
        { "id": "dark",       "name": "dark",       "bg": "#242424", "accent": "#89b4fa" },
        { "id": "oled",       "name": "oled",       "bg": "#000000", "accent": "#3abff8" },
        { "id": "catppuccin", "name": "catppuccin", "bg": "#1e1e2e", "accent": "#cba6f7" },
        { "id": "light",      "name": "light",      "bg": "#eff1f5", "accent": "#1e66f5" },
        { "id": "nord",       "name": "nord",       "bg": "#2e3440", "accent": "#88c0d0" },
        { "id": "rose_pine",  "name": "rose pine",  "bg": "#191724", "accent": "#ebbcba" }
    ]

    Process {
        id: applyThemeProcess
    }

    Column {
        anchors.fill: parent
        anchors.margins: pad
        spacing: 12

        // ── Header ──────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 20

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: "\uf1fc"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Theme.t.theme ?? "Tema"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf00d"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: closeMouse.containsMouse ? Theme.red : Theme.fgMuted
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dock.currentMode = "default"
                }
            }
        }

        // ── Separator ───────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.6)
        }

        // ── 3-column grid ───────────────────────────────────────────────────
        Grid {
            columns: 3
            spacing: 10
            width: parent.width

            Repeater {
                model: themeWrapper.themes

                delegate: Rectangle {
                    required property var modelData

                    width: themeWrapper.cardWidth
                    height: themeWrapper.cardHeight
                    radius: 12

                    color: Qt.rgba(
                        parseInt(modelData.bg.substring(1,3), 16) / 255.0,
                        parseInt(modelData.bg.substring(3,5), 16) / 255.0,
                        parseInt(modelData.bg.substring(5,7), 16) / 255.0,
                        1.0
                    )

                    border.width: Theme.currentTheme === modelData.id ? 2 : 1
                    border.color: Theme.currentTheme === modelData.id
                        ? Qt.rgba(
                            parseInt(modelData.accent.substring(1,3), 16) / 255.0,
                            parseInt(modelData.accent.substring(3,5), 16) / 255.0,
                            parseInt(modelData.accent.substring(5,7), 16) / 255.0,
                            1.0)
                        : (cardMouse.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.07))

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        // Accent pill
                        Rectangle {
                            width: 32; height: 4; radius: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Qt.rgba(
                                parseInt(modelData.accent.substring(1,3), 16) / 255.0,
                                parseInt(modelData.accent.substring(3,5), 16) / 255.0,
                                parseInt(modelData.accent.substring(5,7), 16) / 255.0,
                                1.0
                            )
                        }

                        Text {
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: modelData.id === "light" ? "#4c4f69" : Qt.rgba(1,1,1,0.7)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            applyThemeProcess.command = [
                                Quickshell.env("HOME") + "/pro/dotfiles/theme/apply-theme.sh",
                                modelData.id
                            ];
                            applyThemeProcess.running = true;
                        }
                    }
                }
            }
        }
    }
}
