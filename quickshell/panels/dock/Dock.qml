import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell.Services.Polkit
import "root:/theme"
import "../../widgets"

PanelWindow {
    id: dock
    color: "transparent"

    property var wifiPrompt: null
    property var settingsWindow: null
    property string currentMode: "default"
    property bool isDefaultHovered: false
    property var activeNotification: null
    property alias polkitAgent: polkitAgent

    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: {
            dock.currentMode = "authentication";
        }
    }

    Timer {
        id: dockNotificationTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (dock.currentMode === "notifications") {
                dock.currentMode = "default";
                dock.activeNotification = null;
            }
        }
    }

    Timer {
        id: autoRevertTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (dock.currentMode !== "default") {
                dock.currentMode = "default";
            }
        }
    }

    onCurrentModeChanged: {
        isDefaultHovered = false;
        if (currentMode === "notifications") {
            dockNotificationTimer.restart();
        } else {
            dockNotificationTimer.stop();
        }

        // Auto-revert timer management on mode change
        if (currentMode !== "default") {
            if (!dockHoverHandler.hovered) {
                autoRevertTimer.restart();
            } else {
                autoRevertTimer.stop();
            }
        } else {
            autoRevertTimer.stop();
        }
    }

    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.exclusiveZone: 48
    WlrLayershell.layer: currentMode === "launcher" ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: (currentMode === "launcher" || currentMode === "tray_expanded" || currentMode === "theme" || currentMode === "wallpaper" || currentMode === "language" || currentMode === "authentication") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int windowHeight: 48
    implicitHeight: windowHeight

    property int targetWindowHeight: dockBg.height + 12
    onTargetWindowHeightChanged: {
        if (targetWindowHeight > windowHeight) {
            shrinkTimer.stop();
            windowHeight = targetWindowHeight;
        } else {
            shrinkTimer.targetHeight = targetWindowHeight;
            shrinkTimer.start();
        }
    }

    Timer {
        id: shrinkTimer
        property int targetHeight: 48
        interval: 300
        repeat: false
        onTriggered: dock.windowHeight = targetHeight
    }

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property real currentVolume: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0.0
    onCurrentVolumeChanged: {
        if (currentMode === "default" || currentMode === "volume") {
            currentMode = "volume";
            volumeOsdTimer.restart();
        }
    }

    Timer {
        id: volumeOsdTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (dock.currentMode === "volume")
                dock.currentMode = "default";
        }
    }

    property var activeMonitorWorkspace: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.activeWorkspace : null
    onActiveMonitorWorkspaceChanged: {
        if (activeMonitorWorkspace && (currentMode === "default" || currentMode === "workspaces")) {
            currentMode = "workspaces";
            workspaceOsdTimer.restart();
        }
    }

    property string activeSpecialName: {
        const mon = Hyprland.focusedMonitor;
        if (!mon || !mon.lastIpcObject) return "";
        const sw = mon.lastIpcObject.specialWorkspace;
        return (sw && sw.id !== 0) ? sw.name : "";
    }

    onActiveSpecialNameChanged: {
        if (currentMode === "default" || currentMode === "workspaces") {
            currentMode = "workspaces";
            workspaceOsdTimer.restart();
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            Hyprland.refreshMonitors();
        }
    }

    Timer {
        id: workspaceOsdTimer
        interval: 2500
        repeat: false
        onTriggered: {
            if (dock.currentMode === "workspaces")
                dock.currentMode = "default";
        }
    }

    Rectangle {
        id: dockBg

        anchors.top: parent.top
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter

        color: Theme.bg
        clip: true

        state: dock.currentMode

        Keys.onPressed: (event) => {
            autoRevertTimer.restart();
            if (event.key === Qt.Key_Escape) {
                if (dock.currentMode !== "default") {
                    dock.currentMode = "default";
                    event.accepted = true;
                    return;
                }
            }
            event.accepted = false;
        }

        HoverHandler {
            id: dockHoverHandler
            onHoveredChanged: {
                if (dock.currentMode === "default") {
                    if (hovered) {
                        dockBgHoverTimer.stop();
                        dock.isDefaultHovered = true;
                    } else {
                        dockBgHoverTimer.restart();
                    }
                } else {
                    if (hovered) {
                        autoRevertTimer.stop();
                    } else {
                        autoRevertTimer.restart();
                    }
                }
            }
        }

        Timer {
            id: dockBgHoverTimer
            interval: 350
            repeat: false
            onTriggered: dock.isDefaultHovered = false;
        }

        states: [
            State {
                name: "default"
                PropertyChanges {
                    target: dockBg
                    width: loader.item ? loader.item.implicitWidth + 72 : 197
                    height: loader.item ? loader.item.implicitHeight + 16 : 36
                    radius: dock.isDefaultHovered ? 20 : 18
                }
            },
            State {
                name: "volume"
                PropertyChanges {
                    target: dockBg
                    width: 290
                    height: 36
                    radius: 18
                }
            },
            State {
                name: "workspaces"
                PropertyChanges {
                    target: dockBg
                    width: loader.item ? loader.item.implicitWidth + 48 : 200
                    height: 36
                    radius: 18
                }
            },
            State {
                name: "notifications"
                PropertyChanges {
                    target: dockBg
                    width: loader.item ? loader.item.implicitWidth : 420
                    height: loader.item ? loader.item.implicitHeight : 44
                    radius: 24
                }
            },
            State {
                name: "tray"
                PropertyChanges {
                    target: dockBg
                    width: loader.item ? loader.item.compactWidth + 32 : 100
                    height: 36
                    radius: 18
                }
            },
            State {
                name: "tray_expanded"
                PropertyChanges {
                    target: dockBg
                    width: 280
                    height: loader.item ? loader.item.menuContentHeight + 16 : 180
                    radius: 20
                }
            },
            State {
                name: "launcher"
                PropertyChanges {
                    target: dockBg
                    width: 524
                    height: 440
                    radius: 24
                }
            },
            State {
                name: "theme"
                PropertyChanges {
                    target: dockBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "wallpaper"
                PropertyChanges {
                    target: dockBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "language"
                PropertyChanges {
                    target: dockBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "authentication"
                PropertyChanges {
                    target: dockBg
                    width: 520
                    height: loader.item ? loader.item.implicitHeight : 190
                    radius: 24
                }
            }
        ]

        Behavior on width {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Loader {
            id: loader
            anchors.top: parent.top
            anchors.topMargin: {
                if (dock.currentMode === "tray" || dock.currentMode === "tray_expanded")
                    return 8;
                if (dock.currentMode === "theme" || dock.currentMode === "wallpaper" || dock.currentMode === "language")
                    return 16;
                return 0;
            }
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: (dock.currentMode === "tray" || dock.currentMode === "tray_expanded" || dock.currentMode === "theme" || dock.currentMode === "wallpaper" || dock.currentMode === "language") ? undefined : parent.verticalCenter

            sourceComponent: {
                switch (dock.currentMode) {
                case "volume":
                    return volumeComp;
                case "workspaces":
                    return workspacesComp;
                case "notifications":
                    return notificationsComp;
                case "tray":
                case "tray_expanded":
                    return trayComp;
                case "launcher":
                    return launcherComp;
                case "theme":
                    return themeComp;
                case "wallpaper":
                    return wallpaperComp;
                case "language":
                    return languageComp;
                case "authentication":
                    return authenticationComp;
                default:
                    return defaultComp;
                }
            }
        }
    }

    Component {
        id: defaultComp
        DockDefault {}
    }
    Component {
        id: volumeComp
        DockVolume {}
    }
    Component {
        id: notificationsComp
        DockNotifications {}
    }
    Component {
        id: trayComp
        DockTray {}
    }
    Component {
        id: launcherComp
        DockLauncher {}
    }
    Component {
        id: themeComp
        DockTheme {}
    }
    Component {
        id: wallpaperComp
        DockWallpaper {}
    }
    Component {
        id: languageComp
        DockLanguage {}
    }
    Component {
        id: authenticationComp
        DockAuthentication {}
    }

    Component {
        id: workspacesComp
        Workspaces {}
    }
}
