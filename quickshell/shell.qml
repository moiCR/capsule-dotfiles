//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Io
import "./panels/capsule"
import "./panels/launcher"
import "./panels/wifi"
import "./panels/settings"
import "./widgets"

ShellRoot {
    id: shell

    Capsule {
        id: capsule
        wifiPrompt: wifiPrompt
        settingsWindow: settingsWindow
        toaster: toaster
    }

    Launcher {
        id: launcher
    }

    WifiPrompt {
        id: wifiPrompt
    }

    Settings {
        id: settingsWindow
        wifiPrompt: wifiPrompt
    }

    Toaster {
        id: toaster
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            launcher.visible = !launcher.visible;
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            settingsWindow.toggle();
        }
    }

    IpcHandler {
        target: "capsule"

        function setMode(mode: string): void {
            capsule.currentMode = mode;
        }

        function cycleMode(): void {
            const modes = ["default", "dashboard", "workspaces", "system", "notifications", "tray", "launcher", "theme", "wallpaper", "language", "clipboard", "emoji", "power"];
            let idx = modes.indexOf(capsule.currentMode);
            let nextIdx = (idx + 1) % modes.length;
            capsule.currentMode = modes[nextIdx];
        }
    }
}
