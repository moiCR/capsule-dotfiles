import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import "root:/theme"

Item {
    id: trayWrapper

    property int compactWidth: Math.max(30, trayRow.implicitWidth)
    property int menuContentHeight: 20 + 10 + 1 + 4 + menuItemsColumn.implicitHeight

    implicitWidth: dock.currentMode === "tray_expanded" ? 260 : compactWidth
    implicitHeight: dock.currentMode === "tray_expanded" ? menuContentHeight : 20

    focus: dock.currentMode === "tray_expanded"
    onFocusChanged: { if (focus) trayWrapper.forceActiveFocus() }

    Keys.onEscapePressed: dock.currentMode = "tray"

    MouseArea {
        id: trayMouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse => mouse.accepted = false
        onPressed: mouse => mouse.accepted = false
        onReleased: mouse => mouse.accepted = false
    }

    Timer {
        interval: 5000
        repeat: false
        running: dock.currentMode === "tray_expanded" && !trayMouseArea.containsMouse
        onTriggered: dock.currentMode = "tray"
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Row {
            id: trayRow
            width: implicitWidth
            height: 20
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter
            visible: SystemTray.items.values.length > 0

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    id: trayIconItem
                    width: 20; height: 20
                    implicitWidth: 20; implicitHeight: 20
                    required property SystemTrayItem modelData

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: (iconMouse.containsMouse || (dock.currentMode === "tray_expanded" && ctxOpener.menu === trayIconItem.modelData.menu))
                            ? Theme.bgAlt : "transparent"
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: trayIconItem.modelData.icon
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: iconMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (trayIconItem.modelData.hasMenu) {
                                if (dock.currentMode === "tray_expanded" && ctxOpener.menu === trayIconItem.modelData.menu) {
                                    dock.currentMode = "tray";
                                } else {
                                    ctxOpener.menu = trayIconItem.modelData.menu;
                                    dock.currentMode = "tray_expanded";
                                }
                            } else {
                                trayIconItem.modelData.activate();
                                dock.currentMode = "tray";
                            }
                        }
                    }
                }
            }
        }

        // Empty placeholder
        Text {
            text: Theme.t.no_apps ?? "No Apps"
            color: Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: 11
            visible: SystemTray.items.values.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Context menu list (morphs in/out)
        Column {
            id: menuList
            width: parent.width
            spacing: 4
            opacity: dock.currentMode === "tray_expanded" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.bgAlt
            }

            Column {
                id: menuItemsColumn
                width: parent.width
                spacing: 2

                Repeater {
                    model: ctxOpener.children

                    delegate: Rectangle {
                        id: entryDelegate
                        required property var modelData
                        width: menuItemsColumn.width
                        height: modelData.isSeparator ? 9 : 30
                        radius: 6
                        color: itemArea.containsMouse ? Theme.surface : "transparent"

                        Rectangle {
                            visible: entryDelegate.modelData.isSeparator
                            anchors.centerIn: parent
                            width: parent.width - 24
                            height: 1
                            color: Theme.bgAlt
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            visible: !entryDelegate.modelData.isSeparator

                            Text {
                                text: entryDelegate.modelData.text
                                color: entryDelegate.modelData.enabled === false ? Theme.fgMuted : "#ffffff"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                                anchors.verticalCenter: parent.verticalCenter
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
                                dock.currentMode = "tray";
                            }
                        }
                    }
                }
            }
        }
    }

    QsMenuOpener {
        id: ctxOpener
    }
}
