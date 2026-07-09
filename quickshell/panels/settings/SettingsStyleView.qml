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
        spacing: 24

        // 1. Theme Section
        Column {
            width: parent.width
            spacing: 12

            Text {
                text: Theme.currentLang === "es" ? "Temas del Sistema" : "System Themes"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            }

            // Scrollable Flow
            Flickable {
                width: parent.width
                height: 80
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
                            width: 104
                            height: 68
                            radius: 12
                            
                            // Background color from theme, semi-transparent
                            color: Qt.rgba(
                                parseInt(modelData.bg.substring(1,3), 16)/255.0, 
                                parseInt(modelData.bg.substring(3,5), 16)/255.0, 
                                parseInt(modelData.bg.substring(5,7), 16)/255.0, 
                                0.7
                            )
                            
                            border.color: Theme.currentTheme === modelData.id 
                                ? Theme.accent 
                                : (themeMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.2) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06))
                            border.width: Theme.currentTheme === modelData.id ? 2 : 1
                            
                            // Micro-animations: Hover scaling
                            scale: themeMouse.containsMouse ? 1.03 : 1.0
                            
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                
                                // Accent indicator pill
                                Rectangle {
                                    width: 24; height: 3; radius: 1.5
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: Qt.rgba(
                                        parseInt(modelData.accent.substring(1,3), 16)/255.0, 
                                        parseInt(modelData.accent.substring(3,5), 16)/255.0, 
                                        parseInt(modelData.accent.substring(5,7), 16)/255.0, 
                                        1.0
                                    )
                                }
                                
                                Text {
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: Theme.currentTheme === modelData.id
                                    color: modelData.fg
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    elide: Text.ElideRight
                                    width: parent.width - 12
                                    horizontalAlignment: Text.AlignHCenter
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

        // 2. Wallpaper Section (Replaced List with a Gorgeous Grid Gallery)
        Column {
            width: parent.width
            height: parent.height - 110 // Remaining space
            spacing: 12

            Text {
                text: Theme.currentLang === "es" ? "Galería de Fondos" : "Wallpaper Gallery"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            }

            GridView {
                id: wallpaperGrid
                width: parent.width
                height: parent.height - 30
                cellWidth: 180
                cellHeight: 120
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: settingsWindow ? settingsWindow.wallpapersList : []

                delegate: Item {
                    required property var modelData
                    width: wallpaperGrid.cellWidth
                    height: wallpaperGrid.cellHeight

                    Rectangle {
                        width: 168
                        height: 108
                        anchors.centerIn: parent
                        radius: 12
                        clip: true
                        color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                        
                        border.color: (Theme.currentWallpaper === modelData.path) 
                            ? Theme.accent 
                            : (wallMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06))
                        border.width: (Theme.currentWallpaper === modelData.path) ? 2 : 1
                        
                        scale: wallMouse.containsMouse ? 1.03 : 1.0

                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                        Image {
                            anchors.fill: parent
                            anchors.margins: (Theme.currentWallpaper === modelData.path) ? 2 : 1
                            source: "file://" + encodeURI(modelData.path)
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: width
                            sourceSize.height: height
                            asynchronous: true
                            smooth: true
                        }

                        // Gradient overlay for text readability on hover
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 32
                            color: "transparent"
                            opacity: wallMouse.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: "#d9000000" }
                                }
                            }
                        }

                        // Wallpaper Name
                        Text {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 8
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: "#ffffff"
                            elide: Text.ElideRight
                            opacity: wallMouse.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Active Indicator Badge
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: Theme.accent
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            visible: Theme.currentWallpaper === modelData.path

                            Text {
                                text: "\uf00c" // Checkmark icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.bg
                                anchors.centerIn: parent
                            }
                        }

                        MouseArea {
                            id: wallMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                setWallpaperProcess.command = [Quickshell.env("HOME") + "/pro/dotfiles/theme/set-wallpaper.sh", modelData.path];
                                setWallpaperProcess.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
