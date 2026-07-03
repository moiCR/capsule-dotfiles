import QtQuick
import Quickshell
import Quickshell.Io
import "root:/theme"

Item {
    id: wallpaperWrapper

    readonly property int cardWidth: 122
    readonly property int cardHeight: 74
    readonly property int pad: 16

    implicitWidth: 3 * cardWidth + 2 * 10 + pad * 2   // = 388 + 32 = 420 → matches dock state
    implicitHeight: 2 * cardHeight + 10 + 20 + 12 + 1 + 12 + pad // = 158 + 20 + 12 + 1 + 12 + 16 = 229px + margins

    focus: true
    Component.onCompleted: {
        wallpaperWrapper.forceActiveFocus();
        listWallpapersProcess.running = true;
    }
    Keys.onEscapePressed: capsule.currentMode = "default"

    readonly property string wallpaperDir: {
        let home = Quickshell.env("HOME");
        return Theme.currentLang === "es" ? home + "/Imágenes/Wallpapers" : home + "/Pictures/Wallpapers";
    }

    property var wallpapersList: []

    Process {
        id: listWallpapersProcess
        command: ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/list_wallpapers.py", wallpaperWrapper.wallpaperDir]
        stdout: SplitParser {
            onRead: data => {
                try {
                    wallpaperWrapper.wallpapersList = JSON.parse(data.trim());
                } catch(e) {
                    console.log("Error parsing wallpapers JSON: " + e);
                }
            }
        }
    }

    Process {
        id: setWallpaperProcess
    }

    Column {
        anchors.fill: parent
        anchors.margins: pad
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
                    text: "\uf03e" // Image icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Theme.t.wallpaper ?? "Fondo de Pantalla"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf00d" // Close icon
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

        // ── Scrollable Grid ─────────────────────────────────────────────────
        Flickable {
            width: parent.width
            height: 2 * cardHeight + 10 // fits exactly two rows
            contentWidth: width
            contentHeight: wallpaperGrid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: wallpaperGrid
                columns: 3
                spacing: 10
                width: parent.width

                Repeater {
                    model: wallpaperWrapper.wallpapersList

                    delegate: Rectangle {
                        required property var modelData

                        width: wallpaperWrapper.cardWidth
                        height: wallpaperWrapper.cardHeight
                        radius: 8
                        clip: true

                        color: Theme.bgAlt

                        border.width: Theme.currentWallpaper === modelData.path ? 2 : 1
                        border.color: Theme.currentWallpaper === modelData.path
                            ? Theme.accent
                            : (cardMouse.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.07))

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Image {
                            anchors.fill: parent
                            anchors.margins: Theme.currentWallpaper === modelData.path ? 2 : 1
                            source: "file://" + modelData.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                        }

                        // Gradient overlay at the bottom for readability of the text
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 24
                            color: "transparent"
                            opacity: cardMouse.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: "#cc000000" }
                                }
                            }
                        }

                        Text {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                            font.bold: true
                            color: "#ffffff"
                            elide: Text.ElideRight
                            opacity: cardMouse.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                setWallpaperProcess.command = [
                                    Quickshell.env("HOME") + "/pro/dotfiles/theme/set-wallpaper.sh",
                                    modelData.path
                                ];
                                setWallpaperProcess.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
