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
    implicitHeight: 500

    property var toaster: null

    // Resolve active player from Mpris service
    property var playersList: Mpris.players.values !== undefined ? Mpris.players.values : Mpris.players
    property string selectedPlayerIdentity: ""

    property var activePlayer: {
        if (!playersList || playersList.length === 0) return null;
        
        // 1. Try to find the user selected player
        if (selectedPlayerIdentity !== "") {
            for (var i = 0; i < playersList.length; i++) {
                if (playersList[i].identity === selectedPlayerIdentity) {
                    return playersList[i];
                }
            }
        }
        
        // 2. Try to find a playing Spotify
        for (var i = 0; i < playersList.length; i++) {
            var p = playersList[i];
            if (p.isPlaying && p.identity && p.identity.toLowerCase() === "spotify") {
                return p;
            }
        }
        // 3. Try to find any playing player
        for (var i = 0; i < playersList.length; i++) {
            var p = playersList[i];
            if (p.isPlaying) {
                return p;
            }
        }
        // 4. Try to find a paused Spotify
        for (var i = 0; i < playersList.length; i++) {
            var p = playersList[i];
            if (p.identity && p.identity.toLowerCase() === "spotify") {
                return p;
            }
        }
        return playersList[0];
    }

    function getPlayerIndex(player) {
        if (!playersList || !player) return -1;
        for (var i = 0; i < playersList.length; i++) {
            if (playersList[i] === player) {
                return i;
            }
        }
        return -1;
    }

    function cyclePlayer(forward) {
        if (!playersList || playersList.length <= 1) return;
        
        var currentIndex = getPlayerIndex(activePlayer);
        if (currentIndex === -1) {
            currentIndex = 0;
        }
        
        var nextIndex;
        if (forward) {
            nextIndex = (currentIndex + 1) % playersList.length;
        } else {
            nextIndex = (currentIndex - 1 + playersList.length) % playersList.length;
        }
        
        selectedPlayerIdentity = playersList[nextIndex].identity;
    }

    // Dynamic display properties to support smooth transitions
    property real dragOffset: 0
    property string displayTitle: ""
    property string displayArtist: ""
    property string displayArtUrl: ""
    property string displayIdentity: ""
    property int displayIndex: 0
    property int displayTotal: 0

    property string currentTrackId: activePlayer ? (activePlayer.trackTitle + activePlayer.trackArtist + activePlayer.trackArtUrl) : ""
    onCurrentTrackIdChanged: {
        if (typeof playerContent !== "undefined" && playerContent) {
            if (playerContent.opacity > 0) {
                transitionAnimation.restart();
            } else {
                updateDisplayProperties();
                playerContent.opacity = 1.0;
            }
        } else {
            updateDisplayProperties();
        }
    }

    Component.onCompleted: {
        updateDisplayProperties();
    }

    function updateDisplayProperties() {
        if (activePlayer) {
            displayTitle = activePlayer.trackTitle;
            displayArtist = activePlayer.trackArtist;
            displayArtUrl = activePlayer.trackArtUrl ? resolveArtUrl(activePlayer.trackArtUrl) : "";
            displayIdentity = activePlayer.identity;
            displayIndex = getPlayerIndex(activePlayer) + 1;
            displayTotal = playersList ? playersList.length : 0;
        } else {
            displayTitle = Theme.t.no_media ?? "No media playing";
            displayArtist = Theme.t.silence ?? "Silence";
            displayArtUrl = "";
            displayIdentity = "";
            displayIndex = 0;
            displayTotal = 0;
        }
    }

    NumberAnimation {
        id: dragOffsetAnimation
        target: dashboardRoot
        property: "dragOffset"
        to: 0
        duration: 200
        easing.type: Easing.OutQuad
    }

    SequentialAnimation {
        id: transitionAnimation
        
        ParallelAnimation {
            NumberAnimation {
                target: playerContent
                property: "opacity"
                to: 0
                duration: 120
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: playerContent
                property: "scale"
                to: 0.95
                duration: 120
                easing.type: Easing.OutQuad
            }
        }
        
        ScriptAction {
            script: updateDisplayProperties()
        }
        
        ParallelAnimation {
            NumberAnimation {
                target: playerContent
                property: "opacity"
                to: 1
                duration: 180
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: playerContent
                property: "scale"
                to: 1.0
                duration: 180
                easing.type: Easing.OutQuad
            }
        }
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
        
        return Qt.formatDateTime(d, "dddd, d 'de' MMMM");
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        anchors.bottomMargin: 24
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

            // Power/Session button at the top-right
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf011" // Power icon
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: powerBtnMouse.containsMouse ? Theme.red : Theme.fgMuted
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: powerBtnMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        capsule.currentMode = "session";
                    }
                }
            }
        }

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
                text: Qt.formatDateTime(sysClock.date, "hh:mm")
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

            MouseArea {
                id: swipeArea
                anchors.fill: parent

                property int startX: 0
                property bool dragActive: false

                onPressed: (mouse) => {
                    startX = mouse.x;
                    dragActive = true;
                }

                onPositionChanged: (mouse) => {
                    if (dragActive) {
                        var deltaX = mouse.x - startX;
                        // Elastic multiplier to make the drag feel pleasant but limited
                        dragOffset = deltaX * 0.4;
                    }
                }

                onReleased: (mouse) => {
                    if (!dragActive) return;
                    var diffX = mouse.x - startX;
                    var threshold = 40; // minimum drag distance in pixels
                    if (Math.abs(diffX) > threshold) {
                        if (diffX > 0) {
                            cyclePlayer(false);
                        } else {
                            cyclePlayer(true);
                        }
                    }
                    dragOffsetAnimation.restart();
                    dragActive = false;
                }

                onCanceled: {
                    dragOffsetAnimation.restart();
                    dragActive = false;
                }
            }

            Row {
                id: playerContent
                // Position offset dynamically by dragOffset
                x: 12 + dragOffset
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24
                height: 86
                spacing: 16
                transformOrigin: Item.Center

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
                        source: displayArtUrl
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

                        Row {
                            width: parent.width
                            spacing: 4
                            visible: displayIdentity !== ""
                            Text {
                                text: displayIdentity
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: displayTotal > 1 ? "(" + displayIndex + "/" + displayTotal + ")" : ""
                                color: Theme.fgMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                            }
                        }

                        Text {
                            width: parent.width
                            text: displayTitle
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: displayArtist
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

        // Separator below Media Player
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
        }

        // Notifications Title & Clear Button
        Item {
            width: parent.width
            height: 20

            Text {
                text: Theme.currentLang === "es" ? "Notificaciones" : "Notifications"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: Theme.fgMuted
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: toaster && toaster.historyModel && toaster.historyModel.count > 0
                text: Theme.currentLang === "es" ? "Limpiar" : "Clear"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: clearMouse.containsMouse ? Theme.accent : Theme.fgMuted
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (toaster && toaster.historyModel) {
                            toaster.historyModel.clear();
                        }
                    }
                }
            }
        }

        // Notifications Scroll Area
        Rectangle {
            width: parent.width
            height: 140
            radius: 12
            color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
            clip: true

            Text {
                visible: !toaster || !toaster.historyModel || toaster.historyModel.count === 0
                anchors.centerIn: parent
                text: Theme.currentLang === "es" ? "Sin notificaciones" : "No notifications"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fgMuted
            }

            ListView {
                visible: toaster && toaster.historyModel && toaster.historyModel.count > 0
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                model: toaster ? toaster.historyModel : null

                delegate: Rectangle {
                    required property int index
                    required property string app
                    required property string summary
                    required property string body
                    width: parent.width
                    height: 44
                    radius: 8
                    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.1)
                    border.width: 1
                    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04)

                    // Left Icon indicator (Accent colored circle)
                    Rectangle {
                        id: notifIcon
                        width: 16
                        height: 16
                        radius: 8
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "!"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.accent
                        }
                    }

                    // Content Column (Fixed with direct anchors to prevent width loop and direct role lookups)
                    Column {
                        anchors.left: notifIcon.right
                        anchors.leftMargin: 8
                        anchors.right: dismissBtn.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: (app || "Notification") + " • " + (summary || "")
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }

                        Text {
                            text: body || ""
                            color: Theme.fgMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                            visible: text !== ""
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                    }

                    // Dismiss Button (✕)
                    Text {
                        id: dismissBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: dismissMouse.containsMouse ? Theme.red : Theme.fgMuted

                        MouseArea {
                            id: dismissMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (toaster && toaster.historyModel) {
                                    toaster.historyModel.remove(index);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
