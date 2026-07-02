import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "root:/theme"

PanelWindow {
    id: prompt

    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:wifi_prompt"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    property string ssid: ""
    property var callback: null

    function askPassword(targetSsid, callbackFunc) {
        ssid = targetSsid;
        callback = callbackFunc;
        visible = true;
    }

    function connect() {
        if (callback) {
            callback(passwordField.text);
        }
        visible = false;
    }

    function cancel() {
        if (callback) {
            callback(null);
        }
        visible = false;
    }

    onVisibleChanged: {
        if (visible) {
            passwordField.text = "";
            passwordField.forceActiveFocus();
        }
    }

    // Click outside to cancel
    MouseArea {
        anchors.fill: parent
        onClicked: prompt.cancel()
    }

    Rectangle {
        width: 320
        height: 160
        radius: 14
        anchors.centerIn: parent
        color: Theme.bg
        border.color: Theme.bgAlt
        border.width: 1

        // Prevent clicking inside from triggering cancel
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                width: parent.width
                text: "Conexión Wi-Fi"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                width: parent.width
                text: "Introduce la contraseña para " + prompt.ssid + ":"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            TextField {
                id: passwordField
                width: parent.width
                echoMode: TextInput.Password
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                placeholderText: "Contraseña..."
                
                background: Rectangle {
                    color: Theme.bgAlt
                    radius: 8
                    border.color: passwordField.activeFocus ? Theme.accent : "transparent"
                    border.width: 1
                }

                Keys.onEscapePressed: prompt.cancel()
                Keys.onReturnPressed: prompt.connect()
            }

            Row {
                width: parent.width
                spacing: 8
                layoutDirection: Qt.RightToLeft

                // Connect button
                Rectangle {
                    width: 72
                    height: 28
                    radius: 6
                    color: connectMouse.containsMouse ? Theme.accent : Qt.darker(Theme.accent, 1.1)

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Conectar"
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: prompt.connect()
                    }
                }

                // Cancel button
                Rectangle {
                    width: 72
                    height: 28
                    radius: 6
                    color: cancelMouse.containsMouse ? Theme.surface : Theme.bgAlt

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: prompt.cancel()
                    }
                }
            }
        }
    }
}
