#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_PATH="$1"
HYPR_DIR="$HOME/pro/dotfiles/hypr"

mkdir -p "$HYPR_DIR"
CONF_FILE="$HYPR_DIR/hyprpaper.conf"

# Ensure the daemon is running
if ! pgrep hyprpaper >/dev/null; then
    hyprpaper &
    sleep 0.5
fi

# Preload and set wallpaper live
hyprctl hyprpaper preload "$WALLPAPER_PATH" || true
hyprctl hyprpaper wallpaper ",$WALLPAPER_PATH" || true

# Persist in hyprpaper.conf
cat > "$CONF_FILE" <<EOF
preload = $WALLPAPER_PATH

wallpaper {
    monitor =
    path = $WALLPAPER_PATH
}

splash = false
EOF

# Update current.json
THEME_DIR="$HOME/pro/dotfiles/theme"

python3 - "$THEME_DIR/current.json" "$WALLPAPER_PATH" <<'PY'
import json
import sys

path = sys.argv[1]
wallpaper = sys.argv[2]

with open(path) as f:
    data = json.load(f)

data["wallpaper"] = wallpaper

with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY

echo "Wallpaper set to: $WALLPAPER_PATH"
