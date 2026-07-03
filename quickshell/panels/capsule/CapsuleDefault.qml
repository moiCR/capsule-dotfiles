import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Io
import "root:/theme"
import "../../widgets"

Item {
    id: defaultRoot

    // Hover state managed by parent Dock Window
    readonly property bool isHovered: capsule.isDefaultHovered

    implicitWidth: mainRow.implicitWidth
    implicitHeight: mainRow.implicitHeight

    // Resolve active player from Mpris service
    property var playersList: Mpris.players.values !== undefined ? Mpris.players.values : Mpris.players
    property var activePlayer: {
        if (!playersList || playersList.length === 0) return null;
        
        // 1. Try to find a playing Spotify
        for (var i = 0; i < playersList.length; i++) {
            var p = playersList[i];
            if (p.isPlaying && p.identity && p.identity.toLowerCase() === "spotify") {
                return p;
            }
        }
        // 2. Try to find any playing player
        for (var i = 0; i < playersList.length; i++) {
            var p = playersList[i];
            if (p.isPlaying) {
                return p;
            }
        }
        // 3. Try to find a paused Spotify
        for (var i = 0; i < playersList.length; i++) {
            var p = playersList[i];
            if (p.identity && p.identity.toLowerCase() === "spotify") {
                return p;
            }
        }
        return playersList[0];
    }

    function resolveArtUrl(url) {
        if (!url) return "";
        if (url.indexOf("://") === -1) {
            return "file://" + url;
        }
        return url;
    }

    // Main row containing [ (Visualizer OR Player) | separator | Clock ]
    Row {
        id: mainRow
        spacing: defaultRoot.isHovered ? 20 : 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        
        Behavior on spacing {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }

        // ── 1. Left Element (Visualizer or Player Info) ─────────────────
        Item {
            id: dynamicContainer
            width: defaultRoot.isHovered ? playerRow.implicitWidth : visualizerItem.implicitWidth
            height: defaultRoot.isHovered ? playerRow.implicitHeight : visualizerItem.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            Behavior on width {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }
            Behavior on height {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }

            // Compact Audio Visualizer (visible when not hovered)
            AudioVisualizer {
                id: visualizerItem
                numBars: 3
                showBox: false
                anchors.verticalCenter: parent.verticalCenter
                opacity: defaultRoot.isHovered ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: defaultRoot.isHovered ? 80 : 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Expanded Player Info (visible when hovered)
            Row {
                id: playerRow
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                opacity: defaultRoot.isHovered ? (dynamicContainer.width > 60 ? 1 : 0) : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: defaultRoot.isHovered ? 200 : 80
                        easing.type: Easing.OutCubic
                    }
                }

                // Album Art
                Rectangle {
                    width: 32; height: 32
                    radius: 8
                    clip: true
                    color: Theme.bgAlt
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "\uf001"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fgMuted
                        visible: !artImage.visible
                    }

                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: (activePlayer && activePlayer.trackArtUrl) ? resolveArtUrl(activePlayer.trackArtUrl) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                }

                // Details (Equalizer + Title & Artist)
                Column {
                    width: 100
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Row {
                        width: parent.width
                        spacing: 4

                        // Small active visualizer next to title
                        AudioVisualizer {
                            numBars: 4
                            showBox: false
                            barColor: Theme.green
                            anchors.verticalCenter: parent.verticalCenter
                            visible: activePlayer && activePlayer.isPlaying
                        }

                        Text {
                            width: parent.width - (activePlayer && activePlayer.isPlaying ? 24 : 0)
                            text: activePlayer ? activePlayer.trackTitle : (Theme.t.no_media ?? "No media")
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        width: parent.width
                        text: activePlayer ? activePlayer.trackArtist : (Theme.t.silence ?? "Silence")
                        color: Theme.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // ── 2. Separator line (visible only on hover to separate player from clock)
        Rectangle {
            width: 1
            height: 20
            color: Theme.bgAlt
            opacity: defaultRoot.isHovered ? (dynamicContainer.width > 60 ? 1 : 0) : 0
            visible: opacity > 0
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on opacity {
                NumberAnimation {
                    duration: defaultRoot.isHovered ? 200 : 80
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ── 3. Right Element (Clock & Date) ──────────────────────────────
        Column {
            id: clockContainer
            anchors.verticalCenter: parent.verticalCenter
            spacing: defaultRoot.isHovered ? 2 : 0

            Text {
                text: Qt.formatDateTime(sysClock.date, "hh:mm")
                color: "#ffffff"
                font.family: Theme.fontFamily
                font.pixelSize: defaultRoot.isHovered ? 16 : 14
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
                
                Behavior on font.pixelSize {
                    NumberAnimation { duration: 150 }
                }
            }

            Text {
                text: Qt.formatDateTime(sysClock.date, "ddd, MMM d")
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 9
                anchors.horizontalCenter: parent.horizontalCenter
                visible: defaultRoot.isHovered
                opacity: defaultRoot.isHovered ? 1 : 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }
}
