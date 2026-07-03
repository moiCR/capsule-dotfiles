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
        { "id": "dark",          "name": "dark",         "bg": "#242424", "accent": "#89b4fa" },
        { "id": "oled",          "name": "oled",         "bg": "#000000", "accent": "#3abff8" },
        { "id": "catppuccin",    "name": "catppuccin",   "bg": "#1e1e2e", "accent": "#cba6f7" },
        { "id": "light",         "name": "light",        "bg": "#eff1f5", "accent": "#1e66f5" },
        { "id": "nord",          "name": "nord",         "bg": "#2e3440", "accent": "#88c0d0" },
        { "id": "rose_pine",     "name": "rose pine",    "bg": "#191724", "accent": "#ebbcba" },
        { "id": "ayu_dark",      "name": "ayu dark",     "bg": "#0f1419", "accent": "#f29718" },
        { "id": "ayu_mirage",    "name": "ayu mirage",   "bg": "#171b24", "accent": "#f29718" },
        { "id": "ayu_light",     "name": "ayu light",    "bg": "#fafafa", "accent": "#ff9900" },
        { "id": "github_dark",   "name": "github dark",  "bg": "#0d1117", "accent": "#58a6ff" },
        { "id": "github_light",  "name": "github light", "bg": "#ffffff", "accent": "#0969da" },
        { "id": "dracula",       "name": "dracula",      "bg": "#282a36", "accent": "#bd93f9" },
        { "id": "gruvbox_dark",  "name": "gruvbox dark", "bg": "#282828", "accent": "#fe8019" },
        { "id": "gruvbox_light", "name": "gruvbox light","bg": "#fbf1c7", "accent": "#af3a03" },
        { "id": "tokyonight",    "name": "tokyo night",  "bg": "#1a1b26", "accent": "#7aa2f7" },
        { "id": "one_dark",      "name": "one dark",     "bg": "#282c34", "accent": "#61afef" }
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

        // ── Scrollable Grid ─────────────────────────────────────────────────
        Flickable {
            width: parent.width
            height: 2 * themeWrapper.cardHeight + 10 // fits exactly two rows
            contentWidth: width
            contentHeight: themeGrid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: themeGrid
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
                                color: modelData.id === "light" || modelData.id === "github_light" || modelData.id === "ayu_light" || modelData.id === "gruvbox_light" ? "#4c4f69" : Qt.rgba(1,1,1,0.7)
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
}
