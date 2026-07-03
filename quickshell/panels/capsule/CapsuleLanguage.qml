import QtQuick
import Quickshell
import Quickshell.Io
import "root:/theme"

Item {
    id: langWrapper

    readonly property int cardWidth: 122
    readonly property int cardHeight: 74
    readonly property int pad: 16

    implicitWidth: 3 * cardWidth + 2 * 10 + pad * 2   // = 388 + 32 = 420 → matches dock state
    implicitHeight: 2 * cardHeight + 10 + 20 + 12 + 1 + 12 + pad

    focus: true
    Component.onCompleted: {
        langWrapper.forceActiveFocus();
        listLangsProcess.running = true;
    }
    Keys.onEscapePressed: capsule.currentMode = "default"

    property var langsList: []

    Process {
        id: listLangsProcess
        command: ["python3", Quickshell.env("HOME") + "/pro/dotfiles/lang/list_langs.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    langWrapper.langsList = JSON.parse(data.trim());
                } catch(e) {
                    console.log("Error parsing languages JSON: " + e);
                }
            }
        }
    }

    Process {
        id: writeLangProcess
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
                    text: "\uf1ab" // Globe icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Theme.t.language ?? "Language"
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
                text: "\uf00d" // Close icon
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
                    onClicked: capsule.currentMode = "default"
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
                model: langWrapper.langsList

                delegate: Rectangle {
                    required property var modelData

                    width: langWrapper.cardWidth
                    height: langWrapper.cardHeight
                    radius: 12

                    color: Theme.bgAlt

                    border.width: Theme.currentLang === modelData.id ? 2 : 1
                    border.color: Theme.currentLang === modelData.id
                        ? Theme.accent
                        : (cardMouse.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.07))

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Item {
                        anchors.fill: parent
                        clip: true

                        // Large translucent language code in background
                        Text {
                            anchors.centerIn: parent
                            text: modelData.id.toUpperCase()
                            font.family: Theme.fontFamily
                            font.pixelSize: 42
                            font.bold: true
                            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.03)
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.fg
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // Small indicator dot if selected
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Theme.accent
                                visible: Theme.currentLang === modelData.id
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Theme.currentLang !== modelData.id) {
                                writeLangProcess.command = [
                                    "python3",
                                    "-c",
                                    'import json; import os; path = os.path.expanduser("~/pro/dotfiles/theme/current.json"); d = json.load(open(path)); d["lang"] = "' + modelData.id + '"; json.dump(d, open(path, "w"), indent=2)'
                                ];
                                writeLangProcess.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
