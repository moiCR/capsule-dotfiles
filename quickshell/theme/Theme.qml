pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    property string mode: "dark"
    property string currentTheme: "dark"
    property string currentWallpaper: ""
    property string currentLang: "es"
    property var t: ({})

    property FileView langFile: FileView {
        path: Quickshell.env("HOME") + "/pro/dotfiles/lang/" + theme.currentLang + ".json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            theme.t = JSON.parse(text());
        }
    }

    property color bg: "#1e1e2e"
    property color bgAlt: "#313244"
    property color surface: "#45475a"
    property color fg: "#cdd6f4"
    property color fgMuted: "#a6adc8"
    property color accent: "#89b4fa"
    property color red: "#f38ba8"
    property color green: "#a6e3a1"

    property string fontFamily: "JetBrains Mono Nerd Font"
    property int fontSize: 12
    property int radius: 8
    property int spacing: 8

    property FileView _file: FileView {
        path: Quickshell.env("HOME") + "/pro/dotfiles/theme/current.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const d = JSON.parse(text());
            theme.mode = d.mode ?? theme.mode;
            theme.currentTheme = d.theme ?? (d.mode ?? "dark");
            theme.currentWallpaper = d.wallpaper ?? "";
            theme.currentLang = d.lang ?? theme.currentLang;
            theme.bg = d.bg ?? theme.bg;
            theme.bgAlt = d.bgAlt ?? theme.bgAlt;
            theme.surface = d.surface ?? theme.surface;
            theme.fg = d.fg ?? theme.fg;
            theme.fgMuted = d.fgMuted ?? theme.fgMuted;
            theme.accent = d.accent ?? theme.accent;
            theme.red = d.red ?? theme.red;
            theme.green = d.green ?? theme.green;
        }
    }
}
