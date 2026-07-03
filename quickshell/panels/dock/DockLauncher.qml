import QtQuick
import QtQuick.Controls
import Quickshell
import "root:/theme"

Item {
    implicitWidth: 500
    implicitHeight: 420

    Column {
        id: launcherRoot
        anchors.fill: parent
        spacing: 12
        padding: 8

        property string query: searchField.text

        Component.onCompleted: searchField.forceActiveFocus()

        ScriptModel {
            id: filteredApps
            values: {
                const all = [...DesktopEntries.applications.values].filter(d => d.name).sort((a, b) => a.name.localeCompare(b.name));
                const q = launcherRoot.query.trim().toLowerCase();
                if (q === "") return all;
                return all.filter(d => {
                    const name = (d.name || "").toLowerCase();
                    const comment = (d.comment || "").toLowerCase();
                    return name.includes(q) || comment.includes(q);
                });
            }
        }

        function launchSelected() {
            if (filteredApps.values.length === 0) return;
            const entry = filteredApps.values[appsList.currentIndex];
            entry.execute();
            dock.currentMode = "default";
        }

        Row {
            width: parent.width
            height: 40
            spacing: 10

            Text {
                text: "\uf002"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                color: Theme.fgMuted
                anchors.verticalCenter: parent.verticalCenter
            }

            TextField {
                id: searchField
                width: parent.width - 32
                height: parent.height
                placeholderText: Theme.t.launcher_placeholder ?? "Search..."
                placeholderTextColor: Theme.fgMuted
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 15

                background: Rectangle { color: "transparent" }

                Keys.onEscapePressed: dock.currentMode = "default"
                Keys.onReturnPressed: launcherRoot.launchSelected()
                Keys.onDownPressed: appsList.currentIndex = Math.min(appsList.currentIndex + 1, filteredApps.values.length - 1)
                Keys.onUpPressed: appsList.currentIndex = Math.max(appsList.currentIndex - 1, 0)
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.bgAlt
        }

        ListView {
            id: appsList
            width: parent.width
            height: parent.height - 40 - 1 - parent.spacing * 2
            clip: true
            model: filteredApps
            currentIndex: 0
            spacing: 6

            delegate: Rectangle {
                id: appDelegate
                required property var modelData
                required property int index

                width: appsList.width
                height: 56
                radius: 10
                color: appsList.currentIndex === index ? Theme.surface : "transparent"

                Rectangle {
                    width: 4; height: 24; radius: 2
                    color: Theme.accent
                    anchors.left: parent.left
                    anchors.leftMargin: 3
                    anchors.verticalCenter: parent.verticalCenter
                    visible: appsList.currentIndex === appDelegate.index
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Rectangle {
                        width: 38; height: 38; radius: 8
                        color: Theme.bgAlt
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            source: appDelegate.modelData.icon ? Quickshell.iconPath(appDelegate.modelData.icon) : ""
                            width: 26; height: 26
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 52
                        spacing: 3

                        Text {
                            text: appDelegate.modelData.name
                            color: "#ffffff"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            text: appDelegate.modelData.comment || ""
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            visible: text.length > 0
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: appsList.currentIndex = appDelegate.index
                    onClicked: launcherRoot.launchSelected()
                }
            }
        }
    }
}
