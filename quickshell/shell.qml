//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Io
import "./panels/bar"
import "./panels/launcher"
import "./panels/wifi"
import "./panels/settings"
import "./widgets"

ShellRoot {
    id: shell
    Bar {
        id: bar
        contentLeft: [
            Workspaces {},
            ActiveWindow {}
        ]
        contentCenter: [
            Clock {}
        ]
        contentRight: [
            AudioVisualizer {},
            Tray {},
            System {
                wifiPrompt: wifiPrompt
                settingsWindow: settingsWindow
            }
        ]
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

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            launcher.visible = !launcher.visible;
        }
    }
}
