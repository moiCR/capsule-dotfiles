#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_PATH="$1"
HYPR_DIR="$HOME/pro/dotfiles/hypr"

# Ensure the config directory exists
mkdir -p "$HYPR_DIR"
CONF_FILE="$HYPR_DIR/hyprpaper.conf"

# Ensure the daemon is running
if ! pgrep hyprpaper >/dev/null; then
    hyprpaper &
    sleep 0.5
fi

# Preload and set wallpaper using hyprctl
hyprctl hyprpaper preload "$WALLPAPER_PATH" || true
hyprctl hyprpaper wallpaper ",$WALLPAPER_PATH" || true

# Persist in hyprpaper.conf so it persists after reboot!
echo "preload = $WALLPAPER_PATH" > "$CONF_FILE"
echo "wallpaper = ,$WALLPAPER_PATH" >> "$CONF_FILE"
echo "splash = false" >> "$CONF_FILE"

# Also write to current.json so QML settings can track active wallpaper
THEME_DIR="$HOME/pro/dotfiles/theme"
python3 -c "import json; d = json.load(open('$THEME_DIR/current.json')); d['wallpaper'] = '$WALLPAPER_PATH'; json.dump(d, open('$THEME_DIR/current.json', 'w'), indent=2)"

echo "Wallpaper set to: $WALLPAPER_PATH"
