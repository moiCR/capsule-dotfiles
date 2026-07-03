import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "root:/theme"

Item {
    id: root

    property bool isVertical: Theme.barPosition === "left" || Theme.barPosition === "right"

    implicitWidth: notifsRow.implicitWidth
    implicitHeight: 24
    width: implicitWidth
    height: implicitHeight

    property bool menuOpen: false

    // Shortcut to the global history model from the Toaster daemon
    property var historyModel: (toaster && toaster.historyModel) ? toaster.historyModel : null
    property int count: historyModel ? historyModel.count : 0

    // Header Trigger UI (Icon + Badge)
    Row {
        id: notifsRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            id: bellIcon
            text: "\uf0f3"
            color: clickArea.containsMouse ? Theme.accent : (root.count > 0 ? Theme.fg : Theme.fgMuted)
            font.family: Theme.fontFamily
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Badge showing amount of unread notifications
        Rectangle {
            width: 15
            height: 15
            radius: 7.5
            color: Theme.accent
            visible: root.count > 0
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: root.count
                color: Theme.bg
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
    }

    // Notification Center Dropdown Popup
    PopupWindow {
        id: notifsPopup
        visible: root.menuOpen || closingAnim.running

        property int gap: 20
        anchor.item: root
        anchor.edges: Theme.popupAnchorEdge
        anchor.gravity: Theme.popupAnchorGravity

        implicitWidth: 280
        implicitHeight: 280 + gap
        color: "transparent"

        HyprlandFocusGrab {
            windows: [notifsPopup]
            active: root.menuOpen
            onCleared: root.menuOpen = false
        }

        PropertyAnimation {
            id: closingAnim
            target: notifCard
            property: "opacity"
            to: 0
            duration: 180
            easing.type: Easing.InCubic
        }

        Rectangle {
            id: notifCard
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height - notifsPopup.gap

            color: Theme.bg
            radius: 14
            border.color: Theme.bgAlt
            border.width: 1

            opacity: 0
            scale: 0.9
            y: 8

            states: State {
                name: "open"
                when: root.menuOpen
                PropertyChanges {
                    target: notifCard
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

            // Header Row (Title + Clear All button)
            Row {
                id: headerRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                height: 24

                Text {
                    width: parent.width - 70
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.t.notifications ?? "Notificaciones"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }

                Rectangle {
                    width: 70
                    height: 20
                    radius: 6
                    color: clearMouse.containsMouse ? Theme.accent : Theme.bgAlt
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.count > 0

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: Theme.t.clear_all ?? "Limpiar todo"
                        color: clearMouse.containsMouse ? Theme.bg : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.historyModel) {
                                root.historyModel.clear();
                            }
                            root.menuOpen = false;
                        }
                    }
                }
            }

            Rectangle {
                id: separator
                anchors.top: headerRow.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                height: 1
                color: Theme.bgAlt
            }

            // Empty State text
            Text {
                anchors.centerIn: parent
                text: Theme.t.no_notifications ?? "Sin notificaciones"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                visible: root.count === 0
            }

            // Scrollable Notifications List
            ListView {
                anchors.top: separator.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                anchors.topMargin: 10
                clip: true
                spacing: 8
                model: root.historyModel
                visible: root.count > 0

                delegate: Rectangle {
                    id: notifItem
                    width: ListView.view.width
                    height: 60
                    radius: 10
                    color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                    border.color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2)
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Row {
                            width: parent.width

                            Text {
                                width: parent.width - 20
                                text: model.app ? model.app : "System"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            // Specific dismiss button
                            Text {
                                text: "\uf00d"
                                color: itemDismissMouse.containsMouse ? Theme.red : Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color { ColorAnimation { duration: 120 } }

                                MouseArea {
                                    id: itemDismissMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.historyModel) {
                                            root.historyModel.remove(index);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: model.summary
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: model.body
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
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
                notifsPopup.visible = false;
            }
        }
    }
}
