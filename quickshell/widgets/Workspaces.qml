import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/theme"

Item {
    id: root

    property var currentWs: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.activeWorkspace : null

    property string activeSpecialName: {
        const mon = Hyprland.focusedMonitor;
        if (!mon || !mon.lastIpcObject) return "";
        const sw = mon.lastIpcObject.specialWorkspace;
        return sw ? sw.name : "";
    }
    property bool onSpecial: activeSpecialName !== ""

    property var specialIcons: {
        "steam": "\uf1b6",
        "music": "\uf1bc",
        "discord": "\uf1ff"
    }

    implicitWidth: onSpecial ? specialsRow.implicitWidth + 12 : normalRow.implicitWidth
    implicitHeight: 28

    Behavior on implicitWidth {
        NumberAnimation { duration: 240; easing.type: Easing.OutExpo }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            Hyprland.refreshMonitors();
        }
    }

    Rectangle {
        id: specialsDock
        anchors.centerIn: parent
        z: 1

        width: specialsRow.implicitWidth + 12
        height: 28
        radius: height / 2
        color: Theme.bgAlt
        clip: true

        opacity: root.onSpecial ? 1 : 0
        scale: root.onSpecial ? 1 : 0.85
        enabled: root.onSpecial

        Behavior on width {
            NumberAnimation { duration: 240; easing.type: Easing.OutExpo }
        }
        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutBack }
        }

        Row {
            id: specialsRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: ScriptModel {
                    values: [...Hyprland.workspaces.values].filter(ws => ws.id < 0)
                }

                delegate: Rectangle {
                    id: specialDelegate
                    required property var modelData
                    property bool isActive: modelData.name === root.activeSpecialName
                    property string label: modelData.name.replace("special:", "")
                    property string iconText: root.specialIcons[label] !== undefined ? root.specialIcons[label] : label

                    width: labelText.implicitWidth + (root.specialIcons[label] !== undefined ? 12 : 16)
                    height: 22
                    radius: height / 2
                    color: isActive ? Theme.accent : Theme.bg

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        id: labelText
                        anchors.centerIn: parent
                        text: specialDelegate.iconText
                        color: specialDelegate.isActive ? Theme.bg : Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: root.specialIcons[specialDelegate.label] !== undefined ? 13 : 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: specialDelegate.modelData.activate()
                    }
                }
            }
        }
    }

    Row {
        id: normalRow
        anchors.centerIn: parent
        spacing: 6
        z: 0

        opacity: root.onSpecial ? 0 : 1
        scale: root.onSpecial ? 0.85 : 1
        enabled: !root.onSpecial

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutBack }
        }

        Repeater {
            model: ScriptModel {
                values: [...Hyprland.workspaces.values].filter(ws => ws.id > 0)
            }

            delegate: Rectangle {
                id: wsDelegate
                required property var modelData
                property bool isActive: root.currentWs !== null && root.currentWs.id === modelData.id

                width: 24
                height: 24
                radius: 24
                color: isActive ? Theme.bgAlt : Theme.bg

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\u{f0baf}"
                    color: wsDelegate.isActive ? Theme.accent : Theme.fgMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wsDelegate.modelData.activate()
                }
            }
        }
    }
}