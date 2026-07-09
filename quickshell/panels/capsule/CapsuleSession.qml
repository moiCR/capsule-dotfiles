import QtQuick
import Quickshell
import Quickshell.Io
import "root:/theme"

Item {
    id: sessionWrapper

    implicitWidth: 420
    implicitHeight: 140

    focus: true
    Component.onCompleted: sessionWrapper.forceActiveFocus()
    Keys.onEscapePressed: capsule.currentMode = "default"

    Column {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        anchors.bottomMargin: 20
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
                    text: "\uf011"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Theme.t.session_title ?? "Opciones de Sesión"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf00d"
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

        // ── Buttons Row ─────────────────────────────────────────────────────
        Row {
            width: parent.width
            height: 50
            spacing: 8

            // 1. Lock Screen
            Rectangle {
                width: (parent.width - 32) / 5
                height: parent.height
                radius: 10
                color: lockMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
                border.width: 1
                border.color: lockMouse.containsMouse ? Theme.accent : Qt.rgba(1,1,1,0.08)

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "\uf023"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: lockMouse.containsMouse ? Theme.accent : Theme.fg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: Theme.t.lock ?? "Bloquear"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: lockMouse.containsMouse ? Theme.accent : Theme.fgMuted
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        capsule.currentMode = "default";
                        capsule.runSessionCommand(["hyprlock"]);
                    }
                }
            }

            // 2. Suspend
            Rectangle {
                width: (parent.width - 32) / 5
                height: parent.height
                radius: 10
                color: suspendMouse.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
                border.width: 1
                border.color: suspendMouse.containsMouse ? Theme.accent : Qt.rgba(1,1,1,0.08)

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "\uf186"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: suspendMouse.containsMouse ? Theme.accent : Theme.fg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: Theme.t.suspend ?? "Suspender"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: suspendMouse.containsMouse ? Theme.accent : Theme.fgMuted
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: suspendMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        capsule.currentMode = "default";
                        capsule.runSessionCommand(["systemctl", "suspend"]);
                    }
                }
            }

            // 3. Log Out
            Rectangle {
                width: (parent.width - 32) / 5
                height: parent.height
                radius: 10
                color: logoutMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.08) : Qt.rgba(1,1,1,0.03)
                border.width: 1
                border.color: logoutMouse.containsMouse ? Theme.red : Qt.rgba(1,1,1,0.08)

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "\uf08b"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: logoutMouse.containsMouse ? Theme.red : Theme.fg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: Theme.t.logout ?? "Cerrar"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: logoutMouse.containsMouse ? Theme.red : Theme.fgMuted
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        capsule.currentMode = "default";
                        capsule.runSessionCommand(["hyprctl", "dispatch", "exit"]);
                    }
                }
            }

            // 4. Reboot
            Rectangle {
                width: (parent.width - 32) / 5
                height: parent.height
                radius: 10
                color: rebootMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08) : Qt.rgba(1,1,1,0.03)
                border.width: 1
                border.color: rebootMouse.containsMouse ? Theme.accent : Qt.rgba(1,1,1,0.08)

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "\uf021"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: rebootMouse.containsMouse ? Theme.accent : Theme.fg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: Theme.t.reboot ?? "Reiniciar"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: rebootMouse.containsMouse ? Theme.accent : Theme.fgMuted
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        capsule.currentMode = "default";
                        capsule.runSessionCommand(["systemctl", "reboot"]);
                    }
                }
            }

            // 5. Shutdown
            Rectangle {
                width: (parent.width - 32) / 5
                height: parent.height
                radius: 10
                color: shutdownMouse.containsMouse ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15) : Qt.rgba(1,1,1,0.03)
                border.width: 1
                border.color: shutdownMouse.containsMouse ? Theme.red : Qt.rgba(1,1,1,0.08)

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "\uf011"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: shutdownMouse.containsMouse ? Theme.red : Theme.fg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: Theme.t.shutdown ?? "Apagar"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: shutdownMouse.containsMouse ? Theme.red : Theme.fgMuted
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: shutdownMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        capsule.currentMode = "default";
                        capsule.runSessionCommand(["systemctl", "poweroff"]);
                    }
                }
            }
        }
    }
}
