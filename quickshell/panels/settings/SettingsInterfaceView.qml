import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell
import Quickshell.Io

Item {
    id: interfaceViewRoot
    anchors.fill: parent

    property var settingsWindow: null

    Process {
        id: createLangProcess
        onExited: {
            if (settingsWindow) {
                settingsWindow.listLangsProcess.running = true;
                settingsWindow.showAddLang = false;
            }
        }
    }

    Process {
        id: langWriteProcess
    }

    Process {
        id: addBindProcess
        onExited: {
            hyprReloadProcess.running = true;
        }
    }

    Process {
        id: hyprReloadProcess
        command: ["hyprctl", "reload"]
    }

    Column {
        anchors.fill: parent
        spacing: 16

        // Header and Add Button (Redesigned as an Item to prevent Row layout bugs!)
        Item {
            width: parent.width
            height: 30

            Text {
                text: Theme.currentLang === "es" ? "Atajos de Teclado" : "Keyboard Shortcuts"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 100
                height: 26
                radius: 13
                color: addBindMouse.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                border.color: Theme.accent
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "+"; font.bold: true; color: addBindMouse.containsMouse ? Theme.bg : Theme.accent }
                    Text {
                        text: Theme.currentLang === "es" ? "Nuevo" : "New"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: addBindMouse.containsMouse ? Theme.bg : Theme.accent
                    }
                }

                MouseArea {
                    id: addBindMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (settingsWindow) {
                            settingsWindow.newKeysInput = "";
                            settingsWindow.newCmdInput = "";
                            settingsWindow.showAddBind = true;
                        }
                    }
                }
            }
        }

        // Binds List Table View (Virtualizing ListView)
        Rectangle {
            width: parent.width
            height: parent.height - 130 // Remaining height
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.25)
            radius: 12
            border.color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.1)
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                model: settingsWindow ? settingsWindow.keybindsList : []

                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 38
                    radius: 8
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.15)

                    // Anchored layout instead of Row for exact alignment
                    Rectangle {
                        id: shortcutPill
                        width: 140
                        height: 24
                        radius: 6
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                        border.width: 1
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: modelData.keys
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Text {
                        text: modelData.desc ?? modelData.command
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        anchors.left: shortcutPill.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // 3. Language Selector Row
        Item {
            width: parent.width
            height: 35

            Text {
                text: Theme.currentLang === "es" ? "Idioma:" : "Language:"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 12
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Repeater {
                    model: settingsWindow ? settingsWindow.languagesList : []

                    delegate: Rectangle {
                        required property var modelData
                        width: 70
                        height: 26
                        radius: 13
                        color: Theme.currentLang === modelData.code ? Theme.accent : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.25)
                        border.color: Theme.currentLang === modelData.code ? "transparent" : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.15)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: Theme.currentLang === modelData.code
                            color: Theme.currentLang === modelData.code ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let jsonPath = Quickshell.env("HOME") + "/pro/dotfiles/theme/current.json";
                                langWriteProcess.command = ["python3", "-c", "import json; d = json.load(open('" + jsonPath + "')); d['currentLang'] = '" + modelData.code + "'; json.dump(d, open('" + jsonPath + "', 'w'), indent=2)"];
                                langWriteProcess.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
