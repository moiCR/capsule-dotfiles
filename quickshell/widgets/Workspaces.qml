import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/theme"

Item {
    id: root
    implicitWidth: workspaceText.implicitWidth
    implicitHeight: 18 

    property var currentWs: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.activeWorkspace : null

    // Exact detection logic from the pacman workspaces component
    property string activeSpecialName: {
        const mon = Hyprland.focusedMonitor;
        if (!mon || !mon.lastIpcObject) return "";
        const sw = mon.lastIpcObject.specialWorkspace;
        return (sw && sw.id !== 0) ? sw.name : "";
    }
    property bool onSpecial: activeSpecialName !== ""

    // Force monitor refresh on raw events so lastIpcObject is always up to date
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            Hyprland.refreshMonitors();
        }
    }

    Text {
        id: workspaceText
        anchors.centerIn: parent

        text: {
            // 1. If we are on a special workspace, display its cleaned name
            if (root.onSpecial) {
                let cleanName = root.activeSpecialName.replace("special:", "").replace("scratchpad", "Scratchpad");
                if (cleanName.length > 0) {
                    cleanName = cleanName.charAt(0).toUpperCase() + cleanName.slice(1);
                }
                return "Workspace " + cleanName;
            }

            // 2. Otherwise display the normal workspace number
            if (!currentWs) return "Workspace 1";
            return "Workspace " + currentWs.id;
        }

        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.bold: true
    }
}