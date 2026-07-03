import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "root:/theme"

PanelWindow {
    id: toasterWindow

    // Visual toasters disabled — the dock is now the notification displayer
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:notifications"

    anchors {
        top: true
        right: true
    }

    color: "transparent"

    property int topMargin: 12
    property int rightMargin: 12

    implicitWidth: 320
    implicitHeight: layoutColumn.implicitHeight + topMargin

    // Models for notifications
    property ListModel toasterModel: ListModel {}
    property ListModel historyModel: ListModel {}

    NotificationServer {
        id: notifServer

        onNotification: (notification) => {
            let summaryText = notification.summary || "";
            let bodyText = notification.body || "";
            let app = notification.appName || "Sistema";

            let timestamp = Date.now();
            let newObj = {
                "id": notification.id,
                "app": app,
                "summary": summaryText,
                "body": bodyText,
                "timestamp": timestamp
            };
            
            // Add to screen popup list
            toasterModel.append(newObj);
            
            // Add to history dropdown list
            historyModel.insert(0, newObj);

            // Forward notification to the dock and switch to notifications mode
            if (typeof dock !== "undefined") {
                dock.activeNotification = newObj;
                dock.currentMode = "notifications";
            }

            // Automatically close after 5 seconds
            let timer = Qt.createQmlObject("import QtQuick 2.0; Timer { interval: 5000; running: true; repeat: false }", toasterWindow);
            timer.triggered.connect(function() {
                for (let i = 0; i < toasterModel.count; i++) {
                    if (toasterModel.get(i).timestamp === timestamp) {
                        toasterModel.remove(i);
                        break;
                    }
                }
                timer.destroy();
            });
        }
    }

    Column {
        id: layoutColumn
        width: 300
        spacing: 10
        anchors.right: parent.right
        anchors.rightMargin: toasterWindow.rightMargin
        anchors.top: parent.top
        anchors.topMargin: toasterWindow.topMargin

        Repeater {
            model: toasterWindow.toasterModel

            delegate: Rectangle {
                id: delegateRoot
                width: 300
                height: 72
                radius: 14
                
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.85)
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                border.width: 1.5
                clip: true

                // Entry animation offsets
                opacity: 0
                scale: 0.95
                x: 50

                Component.onCompleted: {
                    appearAnim.start();
                }

                ParallelAnimation {
                    id: appearAnim
                    NumberAnimation { target: delegateRoot; property: "opacity"; to: 1; duration: 250; easing.type: Easing.OutCubic }
                    NumberAnimation { target: delegateRoot; property: "scale"; to: 1; duration: 250; easing.type: Easing.OutBack }
                    NumberAnimation { target: delegateRoot; property: "x"; to: 0; duration: 280; easing.type: Easing.OutBack }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "\uf0f3"
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                    Column {
                        width: parent.width - 48 - 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Row {
                            width: parent.width

                            Text {
                                width: parent.width - 20
                                text: model.app
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "\uf00d"
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                anchors.verticalCenter: parent.verticalCenter
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        toasterWindow.toasterModel.remove(index);
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: model.summary
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: model.body
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
