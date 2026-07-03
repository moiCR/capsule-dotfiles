import QtQuick
import "root:/theme"

Item {
    id: notifRoot

    // Use active notification if available, otherwise fallback to the latest in history
    readonly property var activeNotif: capsule.activeNotification !== null 
        ? capsule.activeNotification 
        : ((toaster && toaster.historyModel && toaster.historyModel.count > 0) ? toaster.historyModel.get(0) : null)

    implicitWidth: 420
    implicitHeight: mainRow.implicitHeight + 32 // 16px padding top + 16px bottom

    Row {
        id: mainRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14

        // ── Left Icon Container (Information circle) ─────────────────────────
        Item {
            width: 32
            height: 32
            anchors.top: parent.top

            // Outer dark circular border
            Rectangle {
                anchors.fill: parent
                radius: 16
                color: Qt.rgba(Theme.bgAlt.r, Theme.bgAlt.g, Theme.bgAlt.b, 0.4)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.05)

                // Inner blue circle
                Rectangle {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    radius: 10
                    color: "#3abff8" // vibrant blue info icon background

                    Text {
                        anchors.centerIn: parent
                        text: "i"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: "#ffffff"
                    }
                }
            }
        }

        // ── Right Content Column (App Name, Summary, Body) ───────────────────
        Column {
            id: textColumn
            width: parent.width - 32 - parent.spacing
            spacing: 3

            // App Name (Brave)
            Text {
                text: notifRoot.activeNotif ? notifRoot.activeNotif.app : (Theme.t.system ?? "System")
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
            }

            // Summary (Notification #4)
            Text {
                width: parent.width
                text: notifRoot.activeNotif ? notifRoot.activeNotif.summary : (Theme.t.no_notifications ?? "No notifications")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                wrapMode: Text.WordWrap
            }

            // Body Text
            Text {
                width: parent.width
                text: notifRoot.activeNotif ? notifRoot.activeNotif.body : ""
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                visible: text !== ""
            }
        }
    }
}
