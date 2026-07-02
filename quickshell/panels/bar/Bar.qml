import Quickshell
import QtQuick
import QtQuick.Layouts
import "./"
import "root:/theme"

PanelWindow {
    id: bar
    property alias contentLeft: leftRow.data
    property alias contentCenter: centerRow.data
    property alias contentRight: rightRow.data
    color: "transparent"
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: 56
    property int dockMargin: 6
    property int dockPadding: 10
    property int dockRadius: 14

    Item {
        anchors.fill: parent

        Rectangle {
            id: dockLeft
            color: Theme.bg
            radius: bar.dockRadius
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: bar.dockMargin
            height: parent.height - bar.dockMargin * 2
            width: leftRow.implicitWidth + bar.dockPadding * 2
            Row {
                id: leftRow
                anchors.centerIn: parent
                spacing: 8
            }
        }

        Rectangle {
            id: dockCenter
            color: Theme.bg
            radius: bar.dockRadius
            anchors.centerIn: parent
            height: parent.height - bar.dockMargin * 2
            width: centerRow.implicitWidth + bar.dockPadding * 2
            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: 8
            }
        }

        Rectangle {
            id: dockRight
            color: Theme.bg
            radius: bar.dockRadius
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: bar.dockMargin
            height: parent.height - bar.dockMargin * 2
            width: rightRow.implicitWidth + bar.dockPadding * 2
            Row {
                id: rightRow
                anchors.centerIn: parent
                spacing: 8
            }
        }
    }
}
