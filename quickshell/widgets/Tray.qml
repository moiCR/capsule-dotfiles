import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import "root:/theme"

Item {
    id: root
    width: toggleBtn.width
    height: toggleBtn.height

    property bool menuOpen: false

    Rectangle {
        id: toggleBtn
        width: 20
        height: 20
        radius: 6
        color: chevronArea.containsMouse ? Theme.bgAlt : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Text {
            id: chevronIcon
            anchors.centerIn: parent
            text: "\uf078"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            rotation: root.menuOpen ? 180 : 0
            Behavior on rotation {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: chevronArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuOpen = !root.menuOpen
        }
    }

    PopupWindow {
        id: trayPopup
        visible: root.menuOpen || closingAnim.running

        property int gap: 20
        property var contextMenuEntry: null
        property bool contextMenuOpen: false

        anchor.item: toggleBtn
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top

        implicitWidth: Math.max(trayColumn.implicitWidth, contextMenuOpen ? ctxList.implicitWidth : 0) + 24
        implicitHeight: trayColumn.implicitHeight + 16 + gap + (contextMenuOpen ? ctxList.implicitHeight + 16 : 0)
        color: "transparent"

        Behavior on implicitWidth {
            NumberAnimation { duration: 280; easing.type: Easing.OutExpo }
        }
        Behavior on implicitHeight {
            NumberAnimation { duration: 280; easing.type: Easing.OutExpo }
        }

        HyprlandFocusGrab {
            windows: [trayPopup]
            active: root.menuOpen
            onCleared: {
                root.menuOpen = false;
                trayPopup.contextMenuOpen = false;
            }
        }

        PropertyAnimation {
            id: closingAnim
            target: content
            property: "opacity"
            to: 0
            duration: 180
            easing.type: Easing.InCubic
        }

        Item {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height - trayPopup.gap

            opacity: 0
            scale: 0.9
            y: 8

            states: State {
                name: "open"
                when: root.menuOpen
                PropertyChanges {
                    target: content
                    opacity: 1
                    scale: 1
                    y: 0
                }
            }

            transitions: Transition {
                NumberAnimation {
                    properties: "opacity,scale,y"
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                radius: 14

                Column {
                    id: mainColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Column {
                        id: trayColumn
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Repeater {
                            model: SystemTray.items

                            Item {
                                id: trayIconItem
                                width: 20
                                height: 20
                                anchors.horizontalCenter: parent.horizontalCenter

                                required property SystemTrayItem modelData

                                Image {
                                    anchors.fill: parent
                                    source: trayIconItem.modelData.icon
                                    smooth: true
                                    fillMode: Image.PreserveAspectFit
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton) {
                                            trayIconItem.modelData.activate();
                                        } else if (mouse.button === Qt.RightButton && trayIconItem.modelData.hasMenu) {
                                            trayPopup.contextMenuEntry = trayIconItem.modelData.menu;
                                            trayPopup.contextMenuOpen = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: opacity > 0
                        opacity: trayPopup.contextMenuOpen ? 1 : 0
                        width: parent.width
                        height: 1
                        color: Theme.bgAlt

                        Behavior on opacity {
                            NumberAnimation { duration: 180 }
                        }
                    }

                    QsMenuOpener {
                        id: ctxOpener
                        menu: trayPopup.contextMenuEntry
                    }

                    Column {
                        id: ctxList
                        visible: opacity > 0
                        opacity: trayPopup.contextMenuOpen ? 1 : 0
                        scale: trayPopup.contextMenuOpen ? 1 : 0.92
                        width: 200
                        spacing: 2

                        transformOrigin: Item.Top

                        Behavior on opacity {
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 280; easing.type: Easing.OutExpo }
                        }

                        Repeater {
                            model: ctxOpener.children

                            delegate: Item {
                                id: entryDelegate
                                required property var modelData
                                width: ctxList.width
                                height: modelData.isSeparator ? 9 : 30

                                Rectangle {
                                    visible: entryDelegate.modelData.isSeparator
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    height: 1
                                    color: Theme.bgAlt
                                }

                                Rectangle {
                                    visible: !entryDelegate.modelData.isSeparator
                                    anchors.fill: parent
                                    radius: Theme.radius / 2
                                    color: itemArea.containsMouse ? Theme.surface : "transparent"

                                    Behavior on color {
                                        ColorAnimation { duration: 100 }
                                    }

                                    Row {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.margins: 10
                                        spacing: 8

                                        Text {
                                            visible: entryDelegate.modelData.buttonType !== undefined && entryDelegate.modelData.buttonType !== 0
                                            text: entryDelegate.modelData.checkState === Qt.Checked ? "✓" : ""
                                            color: Theme.accent
                                            font.pixelSize: 12
                                            width: 12
                                        }

                                        Text {
                                            text: entryDelegate.modelData.text
                                            color: entryDelegate.modelData.enabled === false ? Theme.fgMuted : Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize
                                            elide: Text.ElideRight
                                            width: parent.width - 30
                                        }
                                    }

                                    MouseArea {
                                        id: itemArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: entryDelegate.modelData.enabled !== false
                                        onClicked: {
                                            entryDelegate.modelData.triggered();
                                            trayPopup.contextMenuOpen = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (!root.menuOpen && visible) {
                closingAnim.start();
            }
        }
    }

    Connections {
        target: closingAnim
        function onStopped() {
            if (!root.menuOpen) {
                trayPopup.visible = false;
                trayPopup.contextMenuOpen = false;
            }
        }
    }
}