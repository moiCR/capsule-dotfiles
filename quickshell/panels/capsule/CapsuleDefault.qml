import QtQuick
import Quickshell
import "root:/theme"
import "../../widgets"

Item {
    id: defaultRoot

    implicitWidth: compactRow.implicitWidth
    implicitHeight: 20

    Row {
        id: compactRow
        anchors.centerIn: parent
        spacing: 10

        AudioVisualizer {
            id: visualizerItem
            numBars: 3
            showBox: false
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
