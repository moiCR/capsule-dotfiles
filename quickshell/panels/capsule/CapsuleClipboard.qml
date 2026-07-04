import QtQuick
import Quickshell
import Quickshell.Io
import "root:/theme"

Item {
    id: clipboardWrapper

    readonly property int pad: 16
    implicitWidth: 420
    implicitHeight: 310

    focus: true
    Keys.onEscapePressed: capsule.currentMode = "default"

    ListModel {
        id: clipModel
    }

    // Helper to copy item to clipboard and close
    function copyItem(clipId) {
        copyClipProcess.command = ["bash", "-c", "echo -e '" + clipId + "\\t' | cliphist decode | wl-copy"];
        copyClipProcess.running = true;
        capsule.currentMode = "default";
    }

    // Process to list the top 20 clipboard entries as a clean JSON list
    Process {
        id: listClipsProcess
        command: [
            "bash", "-c",
            "cliphist list | head -n 20 | python3 -c 'import sys, json; out = []; [out.append({\"id\": p[0], \"text\": p[1]}) for line in sys.stdin for p in [line.strip().split(\"\\t\")] if len(p) >= 2]; print(json.dumps(out))'"
        ]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let items = JSON.parse(data.trim());
                    clipModel.clear();
                    for (let i = 0; i < items.length; i++) {
                        let txt = items[i].text || "";
                        // Limit display preview size
                        if (txt.length > 80) txt = txt.substring(0, 80) + "...";
                        clipModel.append({ "clipId": items[i].id, "clipText": txt });
                    }
                } catch(e) {
                    console.log("Error parsing cliphist JSON: " + e);
                }
            }
        }
    }

    // Process to copy selected decoded item
    Process {
        id: copyClipProcess
    }

    // Process to delete specific item
    Process {
        id: deleteClipProcess
        onRunningChanged: {
            if (!running) {
                listClipsProcess.running = true; // refresh list
            }
        }
    }

    // Process to wipe all items
    Process {
        id: wipeClipsProcess
        command: ["cliphist", "wipe"]
        onRunningChanged: {
            if (!running) {
                listClipsProcess.running = true; // refresh list
            }
        }
    }

    Component.onCompleted: {
        clipboardWrapper.forceActiveFocus();
        listClipsProcess.running = true;
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
                    text: "\uf0ea" // Clipboard icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Theme.t.clipboard ?? "Clipboard"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Clear all button (Trash icon)
            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: trashMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15) : "transparent"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    text: "\uf1f8" // Trash icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: trashMouse.containsMouse ? Theme.red : Theme.fgMuted
                    anchors.centerIn: parent

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: trashMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wipeClipsProcess.running = true;
                    }
                }
            }
        }

        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
        }

        // ── Main Content Area ───────────────────────────────────────────────
        Item {
            width: parent.width
            height: 228

            // Empty state placeholder
            Text {
                visible: clipModel.count === 0
                text: Theme.t.clipboard_empty ?? "Clipboard empty"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fgMuted
                anchors.centerIn: parent
            }

            // ListView with items
            ListView {
                id: listView
                anchors.fill: parent
                model: clipModel
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                focus: true

                // Keep keyboard focus inside the ListView
                Component.onCompleted: listView.forceActiveFocus()

                delegate: Rectangle {
                    id: delegateBg
                    width: listView.width
                    height: 36
                    radius: 8

                    // Selected/highlighted state when using arrows, or hovered
                    property bool isCurrent: listView.currentIndex === index
                    color: isCurrent || itemMouse.containsMouse
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                        : Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)

                    border.width: isCurrent ? 1.5 : 1
                    border.color: isCurrent
                        ? Theme.accent
                        : (itemMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : "transparent")

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 6
                        spacing: 8
                        clip: true

                        Text {
                            text: "\uf0f6" // File lines icon
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: isCurrent || itemMouse.containsMouse ? Theme.accent : Theme.fgMuted
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            width: parent.width - 24 - 30
                            text: model.clipText
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: isCurrent || itemMouse.containsMouse ? Theme.fg : Theme.fgMuted
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Individual delete button
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 5
                            color: singleTrashMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15) : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "\uf1f8" // Trash icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: singleTrashMouse.containsMouse ? Theme.red : Theme.fgMuted
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: singleTrashMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    deleteClipProcess.command = ["bash", "-c", "echo -e '" + model.clipId + "\\t' | cliphist delete"];
                                    deleteClipProcess.running = true;
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        // Fill parent but subtract the delete button on the right
                        width: parent.width - 32
                        height: parent.height
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            copyItem(model.clipId);
                        }
                    }
                }

                // Keyboard handling inside the ListView
                Keys.onReturnPressed: {
                    if (currentIndex >= 0 && currentIndex < model.count) {
                        let item = model.get(currentIndex);
                        copyItem(item.clipId);
                    }
                }
            }
        }
    }
}
