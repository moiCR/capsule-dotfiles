import QtQuick

Item {
    id: root

    property bool expanded: false
    property Component collapsedContent
    property Component expandedContent

    implicitWidth: loader.item ? loader.item.width : 0
    implicitHeight: parent ? parent.height : 0

    width: implicitWidth
    height: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Loader {
        id: loader
        anchors.centerIn: parent
        sourceComponent: root.expanded ? root.expandedContent : root.collapsedContent
    }
}