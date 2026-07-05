import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "root:/theme"
import "../../widgets"

Item {
    id: defaultRoot

    implicitWidth: compactRow.implicitWidth
    implicitHeight: 20

    // Resolve if any media player is actively playing
    property var playersList: Mpris.players.values !== undefined ? Mpris.players.values : Mpris.players
    property bool isMediaPlaying: {
        if (!playersList || playersList.length === 0) return false;
        for (var i = 0; i < playersList.length; i++) {
            if (playersList[i].isPlaying) {
                return true;
            }
        }
        return false;
    }

    Row {
        id: compactRow
        anchors.centerIn: parent
        spacing: isMediaPlaying ? 10 : 0

        AudioVisualizer {
            id: visualizerItem
            numBars: 3
            showBox: false
            visible: defaultRoot.isMediaPlaying
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Qt.formatDateTime(sysClock.date, "hh:mm")
            color: "#ffffff"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
