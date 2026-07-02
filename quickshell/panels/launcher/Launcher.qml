import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "root:/theme"

PanelWindow {
    id: launcher
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:launcher"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    property bool expanded: searchField.text.length > 0

    onVisibleChanged: if (visible) {
        searchField.text = "";
        searchField.forceActiveFocus();
        list.currentIndex = 0;
    }

    property string query: searchField.text

    ScriptModel {
        id: filtered
        values: {
            const all = [...DesktopEntries.applications.values].filter(d => d.name).sort((a, b) => a.name.localeCompare(b.name));

            const q = launcher.query.trim().toLowerCase();
            if (q === "")
                return all;

            return all.filter(d => {
                const name = (d.name || "").toLowerCase();
                const comment = (d.comment || "").toLowerCase();
                return name.includes(q) || comment.includes(q);
            });
        }
    }

    function launchSelected() {
        if (filtered.values.length === 0)
            return;
        const entry = filtered.values[list.currentIndex];
        entry.execute();
        launcher.visible = false;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcher.visible = false
    }

    Rectangle {
        id: box
        clip: true

        width: launcher.expanded ? 700 : hintText.implicitWidth + 48
        height: launcher.expanded ? 400 : 50
        radius: launcher.expanded ? Theme.radius * 2 : height / 2

        anchors.centerIn: parent
        color: Theme.bg
        border.color: Theme.bgAlt
        border.width: 1

        Behavior on width {
            NumberAnimation { duration: 380; easing.type: Easing.OutExpo }
        }
        Behavior on height {
            NumberAnimation { duration: 380; easing.type: Easing.OutExpo }
        }
        Behavior on radius {
            NumberAnimation { duration: 380; easing.type: Easing.OutExpo }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Text {
            id: hintText
            anchors.centerIn: parent
            text: Theme.t.launcher_hint ?? "\uf002 Type anything..."
            font.family: Theme.fontFamily
            font.pixelSize: 22
            color: Theme.fgMuted
            opacity: launcher.expanded ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }
        }

        
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: Theme.spacing
            opacity: launcher.expanded ? 1 : 0
            clip: true

            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
            }

            TextField {
                id: searchField
                width: parent.width
                placeholderText: Theme.t.launcher_placeholder ?? "Buscar aplicación..."
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 22
                background: Rectangle {
                    color: Theme.bgAlt
                    radius: Theme.radius
                }

                Keys.onEscapePressed: {
                    if (text.length > 0)
                        text = "";
                    else
                        launcher.visible = false;
                }
                Keys.onReturnPressed: launcher.launchSelected()
                Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, filtered.values.length - 1)
                Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
            }

            ListView {
                id: list
                width: parent.width
                height: parent.height - searchField.height - Theme.spacing
                clip: true
                model: filtered
                currentIndex: 0

                delegate: Rectangle {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    width: list.width
                    height: 44
                    radius: Theme.radius
                    color: list.currentIndex === index ? Theme.surface : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Image {
                            source: delegateRoot.modelData.icon ? Quickshell.iconPath(delegateRoot.modelData.icon) : ""
                            width: 28
                            height: 28
                        }

                        Text {
                            text: delegateRoot.modelData.name
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = delegateRoot.index
                        onClicked: launcher.launchSelected()
                    }
                }
            }
        }
    }
}