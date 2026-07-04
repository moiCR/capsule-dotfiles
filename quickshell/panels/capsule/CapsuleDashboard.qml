import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Io
import "root:/theme"
import "../../widgets"

Item {
    id: dashboardRoot

    implicitWidth: 348
    implicitHeight: 294

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

    function getBatteryIcon() {
        if (!UPower.displayDevice) return "\uf240";
        let p = UPower.displayDevice.percentage * 100;
        let state = UPower.displayDevice.state;
        if (state === 1) return "\uf0e7"; // Charging
        if (p > 90) return "\uf240";
        if (p > 60) return "\uf241";
        if (p > 40) return "\uf242";
        if (p > 15) return "\uf243";
        return "\uf244";
    }

    function getGreeting() {
        let hour = sysClock.date.getHours();
        let isSp = (Theme.t && Theme.t.lang_name === "Español");
        
        if (hour < 6) {
            return isSp ? "¡Buenas noches, Moi! \u2728" : "Good night, Moi! \u2728";
        }
        if (hour < 12) {
            return isSp ? "¡Buenos días, Moi! \u2600\ufe0f" : "Good morning, Moi! \u2600\ufe0f";
        }
        if (hour < 18) {
            return isSp ? "¡Buenas tardes, Moi! \ud83c\udf05" : "Good afternoon, Moi! \ud83c\udf05";
        }
        return isSp ? "¡Buenas noches, Moi! \ud83c\udf03" : "Good night, Moi! \ud83c\udf03";
    }

    function getFormattedDate() {
        let d = sysClock.date;
        let dayName = "";
        let monthName = "";
        let isSp = (Theme.t && Theme.t.lang_name === "Español");
        
        if (Theme.t && Theme.t.months_full && Theme.t.days) {
            let dayNamesLong = {
                "es": ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"],
                "en": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            };
            
            let dayList = isSp ? dayNamesLong["es"] : dayNamesLong["en"];
            dayName = dayList[d.getDay()];
            monthName = Theme.t.months_full[d.getMonth()];
            
            if (isSp) {
                return dayName + ", " + d.getDate() + " de " + monthName;
            } else {
                return dayName + ", " + monthName + " " + d.getDate();
            }
        }
        
        // Safe fallback escaping 'de'
        return Qt.formatDateTime(d, "dddd, d 'de' MMMM");
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header (Dashboard title & Battery)
        Item {
            width: parent.width
            height: 24

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                    text: "\uf0e4" // Dashboard icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.accent
                }
                Text {
                    text: "Dashboard"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.fg
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Text {
                    text: getBatteryIcon()
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: UPower.displayDevice && UPower.displayDevice.state === 1 ? Theme.green : Theme.fgMuted
                }
                Text {
                    text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "100%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.fg
                }
            }
        }

        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
        }

        // Greeting & Large Time Display
        Column {
            width: parent.width
            spacing: 2

            Text {
                text: getGreeting()
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.accent
            }

            Text {
                text: getFormattedDate()
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fgMuted
            }

            Text {
                text: Qt.formatDateTime(sysClock.date, "hh:mm:ss")
                font.family: Theme.fontFamily
                font.pixelSize: 22
                font.bold: true
                color: "#ffffff"
            }
        }

        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
        }

        // Media Player widget
        Rectangle {
            width: parent.width
            height: 110
            radius: 12
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.3)
            border.width: 1
            border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
            clip: true

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16

                // Album Art
                Rectangle {
                    width: 86
                    height: 86
                    radius: 8
                    color: Theme.bgAlt
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "\uf001" // Music note
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
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

                // Metadata & Player Controls
                Column {
                    width: parent.width - 86 - 16 - 24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Column {
                        width: parent.width
                        spacing: 2

                        Text {
                            width: parent.width
                            text: activePlayer ? activePlayer.trackTitle : (Theme.t.no_media ?? "No media playing")
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: activePlayer ? activePlayer.trackArtist : (Theme.t.silence ?? "Silence")
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    // Media Control Row
                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Prev
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: prevMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent"
                            Text {
                                text: "\uf048" // Backward icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: prevMouse.containsMouse ? Theme.accent : Theme.fg
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (activePlayer) activePlayer.previous()
                            }
                        }

                        // Play/Pause
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: playMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                            Text {
                                text: activePlayer && activePlayer.isPlaying ? "\uf04c" : "\uf04b"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.accent
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (activePlayer) activePlayer.isPlaying = !activePlayer.isPlaying
                            }
                        }

                        // Next
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: nextMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent"
                            Text {
                                text: "\uf051" // Forward icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: nextMouse.containsMouse ? Theme.accent : Theme.fg
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (activePlayer) activePlayer.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
