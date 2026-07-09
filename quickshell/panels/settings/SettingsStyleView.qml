import QtQuick
import QtQuick.Controls
import "root:/theme"
import Quickshell
import Quickshell.Io

Item {
    id: styleViewRoot
    anchors.fill: parent

    property var settingsWindow: null

    Component.onCompleted: {
        Theme.listThemesProcess.running = true;
    }

    Process {
        id: themeToggleProcess
    }

    Process {
        id: setWallpaperProcess
    }

    Column {
        anchors.fill: parent
        spacing: 20

        // 1. Theme Section
        Column {
            width: parent.width
            spacing: 8

            Text {
                text: Theme.currentLang === "es" ? "Temas" : "Themes"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Flickable {
                width: parent.width
                height: 90
                contentWidth: themeFlow.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: themeFlow
                    height: parent.height
                    spacing: 10

                    Repeater {
                        model: Theme.themesList

                        delegate: Rectangle {
                            required property var modelData
                            width: 100
                            height: 70
                            radius: 10
                            color: Qt.rgba(parseInt(modelData.bg.substring(1,3), 16)/255.0, parseInt(modelData.bg.substring(3,5), 16)/255.0, parseInt(modelData.bg.substring(5,7), 16)/255.0, 0.65)
                            border.color: Theme.currentTheme === modelData.id ? Theme.accent : (themeMouse.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.07))
                            border.width: Theme.currentTheme === modelData.id ? 2 : 1

                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle {
                                    width: 20; height: 3; radius: 1.5
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: Qt.rgba(parseInt(modelData.accent.substring(1,3), 16)/255.0, parseInt(modelData.accent.substring(3,5), 16)/255.0, parseInt(modelData.accent.substring(5,7), 16)/255.0, 1.0)
                                }
                                Text {
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: modelData.fg
                                }
                            }

                            MouseArea {
                                id: themeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    themeToggleProcess.command = [Quickshell.env("HOME") + "/pro/dotfiles/theme/apply-theme.sh", modelData.id];
                                    themeToggleProcess.running = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. Wallpaper Section
        Column {
            width: parent.width
            height: parent.height - 140 // Remaining space
            spacing: 8

            Text {
                text: Theme.currentLang === "es" ? "Fondos de Pantalla" : "Wallpapers"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            ListView {
                id: wallpaperListView
                width: parent.width
                height: parent.height - 30
                clip: true
                spacing: 8
                model: settingsWindow ? settingsWindow.wallpapersList : []

                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 80
                    radius: 12
                    color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                    border.color: (Theme.currentWallpaper === modelData.path) ? Theme.accent : (wallMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2))
                    border.width: (Theme.currentWallpaper === modelData.path) ? 2 : 1
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 12

                        // Wallpaper Preview Thumbnail (fully optimized decode size!)
                        Rectangle {
                            width: 100
                            height: 64
                            radius: 8
                            clip: true
                            color: Theme.bg

                            Image {
                                anchors.fill: parent
                                source: "file://" + encodeURI(modelData.path)
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: width
                                sourceSize.height: height
                                asynchronous: true
                            }
                        }

                        // Info Column
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: modelData.name
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                text: modelData.path
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                elide: Text.ElideMiddle
                                width: 240
                            }
                        }
                    }

                    MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            setWallpaperProcess.command = ["python3", Quickshell.env("HOME") + "/pro/dotfiles/theme/apply-theme.sh", "--wallpaper", modelData.path];
                            setWallpaperProcess.running = true;
                        }
                    }
                }
            }
        }
    }
}
