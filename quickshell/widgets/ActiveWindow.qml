import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "root:/theme"

Item {
    id: root

    implicitWidth: Math.min(textItem.implicitWidth, 200)
    implicitHeight: 24
    width: implicitWidth
    height: implicitHeight
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Behavior on width {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    property bool menuOpen: false
    property var targetToplevel: null

    onMenuOpenChanged: {
        if (menuOpen) {
            targetToplevel = Hyprland.activeToplevel;
        }
    }

    Text {
        id: textItem
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : (Theme.t.desktop ?? "Desktop")
        color: clickArea.containsMouse && clickArea.enabled ? Theme.accent : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize

        elide: Text.ElideRight
        clip: true

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: Hyprland.activeToplevel !== null
        onClicked: root.menuOpen = !root.menuOpen
    }

    PopupWindow {
        id: activeWinPopup
        visible: root.menuOpen || closingAnim.running

        property int gap: 20
        anchor.item: root
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top

        implicitWidth: 280
        implicitHeight: 226 + gap
        color: "transparent"

        HyprlandFocusGrab {
            windows: [activeWinPopup]
            active: root.menuOpen
            onCleared: root.menuOpen = false
        }

        PropertyAnimation {
            id: closingAnim
            target: winCard
            property: "opacity"
            to: 0
            duration: 180
            easing.type: Easing.InCubic
        }

        Rectangle {
            id: winCard
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height - activeWinPopup.gap

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
                    target: winCard
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

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    width: parent.width
                    text: root.targetToplevel ? root.targetToplevel.title : (Theme.t.active_window ?? "Ventana Activa")
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: previewContainer
                    width: parent.width
                    height: 140
                    radius: 8
                    color: Theme.bgAlt
                    border.color: Theme.surface
                    border.width: 1
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        text: Theme.t.no_preview ?? "Sin vista previa"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        visible: root.targetToplevel === null || root.targetToplevel.wayland === null
                    }

                    ScreencopyView {
                        anchors.fill: parent
                        captureSource: root.targetToplevel ? root.targetToplevel.wayland : null
                        live: true
                        paintCursor: false
                        visible: root.targetToplevel !== null && root.targetToplevel.wayland !== null
                    }
                }

                Rectangle {
                    id: killButton
                    width: parent.width
                    height: 32
                    radius: 8
                    color: killMouse.containsMouse ? Theme.red : Qt.darker(Theme.red, 1.1)

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "\uf00d"
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }

                        Text {
                            text: Theme.t.close_window ?? "Cerrar Ventana"
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: killMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.targetToplevel) {
                                root.targetToplevel.close();
                            }
                            root.menuOpen = false;
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
                activeWinPopup.visible = false;
            }
        }
    }
}