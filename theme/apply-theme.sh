#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$HOME/pro/dotfiles/theme"

MODE="${1:-}"

if [[ -z "$MODE" ]]; then
    CURRENT_MODE=$(python3 -c "import json; print(json.load(open('$THEME_DIR/current.json'))['mode'])" 2>/dev/null || echo "dark")
    if [[ "$CURRENT_MODE" == "dark" ]]; then
        MODE="light"
    else
        MODE="dark"
    fi
fi

SRC="$THEME_DIR/$MODE.json"
LANG=$(python3 -c "import json; print(json.load(open('$THEME_DIR/current.json'))['lang'])" 2>/dev/null || echo "es")
cp "$SRC" "$THEME_DIR/current.json"
python3 -c "import json; d = json.load(open('$THEME_DIR/current.json')); d['lang'] = '$LANG'; d['theme'] = '$MODE'; json.dump(d, open('$THEME_DIR/current.json', 'w'), indent=2)"

python3 - "$SRC" > "$HOME/pro/dotfiles/hypr/modules/theme.lua" <<'PYEOF'
import json, sys

data = json.load(open(sys.argv[1]))
print("return {")
for k, v in data.items():
    print(f'    {k} = "{v}",')
print("}")
PYEOF

python3 - "$SRC" <<'PYEOF'
import json, sys

data = json.load(open(sys.argv[1]))
bg = data.get('bg', '#1e1e2e')
bg_alt = data.get('bgAlt', '#11111b')
surface = data.get('surface', '#313244')
fg = data.get('fg', '#cdd6f4')
fg_muted = data.get('fgMuted', '#a6adc8')
accent = data.get('accent', '#89b4fa')
red = data.get('red', '#f38ba8')
green = data.get('green', '#a6e3a1')

palette_colors = {
    0: bg_alt,
    1: red,
    2: green,
    3: "#f9e2af",
    4: accent,
    5: "#cba6f7",
    6: "#89dceb",
    7: fg_muted,
    8: surface,
    9: red,
    10: green,
    11: "#f9e2af",
    12: accent,
    13: "#cba6f7",
    14: "#89dceb",
    15: fg
}

ghostty_config = f"background = {bg}\nforeground = {fg}\n"
for index, color in palette_colors.items():
    ghostty_config += f"palette = {index}={color}\n"

with open("/home/moi/pro/dotfiles/terminals/theme.ghostty", "w") as f:
    f.write(ghostty_config)
PYEOF


MODE_TYPE=$(python3 -c "import json; print(json.load(open('$SRC'))['mode'])" 2>/dev/null || echo "dark")
if [[ "$MODE_TYPE" == "dark" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

    xfconf-query -c xsettings -p /Net/ThemeName -s 'Adwaita-dark' 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s 'Adwaita' 2>/dev/null || true
    xfconf-query -c xsettings -p /Gtk/ApplicationPreferDarkTheme -s true -n -t bool 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'

    xfconf-query -c xsettings -p /Net/ThemeName -s 'Adwaita' 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s 'Adwaita' 2>/dev/null || true
    xfconf-query -c xsettings -p /Gtk/ApplicationPreferDarkTheme -s false -n -t bool 2>/dev/null || true
fi

echo "Tema: $MODE"
