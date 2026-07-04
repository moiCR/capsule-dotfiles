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
    id: capsule
    color: "transparent"

    property var wifiPrompt: null
    property var settingsWindow: null
    property string currentMode: "default"

    property var activeNotification: null
    property alias polkitAgent: polkitAgent

    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: {
            capsule.currentMode = "authentication";
        }
    }

    Timer {
        id: capsuleNotificationTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (capsule.currentMode === "notifications") {
                capsule.currentMode = "default";
                capsule.activeNotification = null;
            }
        }
    }

    Timer {
        id: autoRevertTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (capsule.currentMode !== "default") {
                capsule.currentMode = "default";
            }
        }
    }

    onCurrentModeChanged: {
        if (currentMode === "notifications") {
            capsuleNotificationTimer.restart();
        } else {
            capsuleNotificationTimer.stop();
        }

        // Auto-revert timer management on mode change
        if (currentMode !== "default") {
            if (!capsuleHoverHandler.hovered) {
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

    WlrLayershell.exclusiveZone: 35
    WlrLayershell.layer: currentMode === "launcher" ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: (currentMode === "launcher" || currentMode === "tray_expanded" || currentMode === "theme" || currentMode === "wallpaper" || currentMode === "language" || currentMode === "authentication" || currentMode === "clipboard" || currentMode === "emoji") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int windowHeight: 48
    implicitHeight: windowHeight

    property int targetWindowHeight: capsuleBg.height + 12
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
        onTriggered: capsule.windowHeight = targetHeight
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
            if (capsule.currentMode === "volume")
                capsule.currentMode = "default";
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

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            let active = Hyprland.activeToplevel;
            let specName = capsule.activeSpecialName;
            if (specName.indexOf("dropdown") !== -1) {
                if (!active || active.class !== "com.domain.dropdown") {
                    hideDropdownProcess.running = true;
                }
            }
        }
    }

    Process {
        id: hideDropdownProcess
        command: ["hyprctl", "dispatch", "hl.dsp.workspace.toggle_special('dropdown')"]
    }

    Timer {
        id: workspaceOsdTimer
        interval: 2500
        repeat: false
        onTriggered: {
            if (capsule.currentMode === "workspaces")
                capsule.currentMode = "default";
        }
    }

    Rectangle {
        id: capsuleBg

        anchors.top: parent.top
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter

        color: Theme.bg
        clip: true

        state: capsule.currentMode

        Keys.onPressed: (event) => {
            autoRevertTimer.restart();
            if (event.key === Qt.Key_Escape) {
                if (capsule.currentMode !== "default") {
                    capsule.currentMode = "default";
                    event.accepted = true;
                    return;
                }
            }
            event.accepted = false;
        }

        HoverHandler {
            id: capsuleHoverHandler
            onHoveredChanged: {
                if (capsule.currentMode === "default") {
                    if (hovered) {
                        capsuleBgHoverTimer.stop();
                        capsule.currentMode = "dashboard";
                    }
                } else if (capsule.currentMode === "dashboard") {
                    if (!hovered) {
                        capsuleBgHoverTimer.restart();
                    } else {
                        capsuleBgHoverTimer.stop();
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
            id: capsuleBgHoverTimer
            interval: 350
            repeat: false
            onTriggered: {
                if (capsule.currentMode === "dashboard") {
                    capsule.currentMode = "default";
                }
            }
        }

        states: [
            State {
                name: "default"
                PropertyChanges {
                    target: capsuleBg
                    width: loader.item ? loader.item.implicitWidth + 72 : 197
                    height: loader.item ? loader.item.implicitHeight + 16 : 36
                    radius: 18
                }
            },
            State {
                name: "dashboard"
                PropertyChanges {
                    target: capsuleBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "volume"
                PropertyChanges {
                    target: capsuleBg
                    width: 290
                    height: 36
                    radius: 18
                }
            },
            State {
                name: "workspaces"
                PropertyChanges {
                    target: capsuleBg
                    width: loader.item ? loader.item.implicitWidth + 48 : 200
                    height: 36
                    radius: 18
                }
            },
            State {
                name: "notifications"
                PropertyChanges {
                    target: capsuleBg
                    width: loader.item ? loader.item.implicitWidth : 420
                    height: loader.item ? loader.item.implicitHeight : 44
                    radius: 24
                }
            },
            State {
                name: "tray"
                PropertyChanges {
                    target: capsuleBg
                    width: loader.item ? loader.item.compactWidth + 32 : 100
                    height: 36
                    radius: 18
                }
            },
            State {
                name: "tray_expanded"
                PropertyChanges {
                    target: capsuleBg
                    width: 280
                    height: loader.item ? loader.item.menuContentHeight + 16 : 180
                    radius: 20
                }
            },
            State {
                name: "launcher"
                PropertyChanges {
                    target: capsuleBg
                    width: 524
                    height: 440
                    radius: 24
                }
            },
            State {
                name: "theme"
                PropertyChanges {
                    target: capsuleBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "wallpaper"
                PropertyChanges {
                    target: capsuleBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "language"
                PropertyChanges {
                    target: capsuleBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "clipboard"
                PropertyChanges {
                    target: capsuleBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "emoji"
                PropertyChanges {
                    target: capsuleBg
                    width: 420
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "authentication"
                PropertyChanges {
                    target: capsuleBg
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
                if (capsule.currentMode === "tray" || capsule.currentMode === "tray_expanded")
                    return 8;
                if (capsule.currentMode === "theme" || capsule.currentMode === "wallpaper" || capsule.currentMode === "language" || capsule.currentMode === "clipboard" || capsule.currentMode === "emoji" || capsule.currentMode === "dashboard")
                    return 16;
                return 0;
            }
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: (capsule.currentMode === "theme" || capsule.currentMode === "wallpaper" || capsule.currentMode === "language" || capsule.currentMode === "clipboard" || capsule.currentMode === "emoji" || capsule.currentMode === "dashboard") ? undefined : parent.verticalCenter

            sourceComponent: {
                switch (capsule.currentMode) {
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
                case "clipboard":
                    return clipboardComp;
                case "emoji":
                    return emojiComp;
                case "dashboard":
                    return dashboardComp;
                default:
                    return defaultComp;
                }
            }
        }
    }

    Component {
        id: defaultComp
        CapsuleDefault {}
    }
    Component {
        id: volumeComp
        CapsuleVolume {}
    }
    Component {
        id: notificationsComp
        CapsuleNotifications {}
    }
    Component {
        id: trayComp
        CapsuleTray {}
    }
    Component {
        id: launcherComp
        CapsuleLauncher {}
    }
    Component {
        id: themeComp
        CapsuleTheme {}
    }
    Component {
        id: wallpaperComp
        CapsuleWallpaper {}
    }
    Component {
        id: languageComp
        CapsuleLanguage {}
    }
    Component {
        id: authenticationComp
        CapsuleAuthentication {}
    }

    Component {
        id: clipboardComp
        CapsuleClipboard {}
    }

    Component {
        id: emojiComp
        CapsuleEmoji {}
    }

    Component {
        id: workspacesComp
        Workspaces {}
    }

    Component {
        id: dashboardComp
        CapsuleDashboard {}
    }
}
