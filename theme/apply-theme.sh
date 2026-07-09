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

SRC="$THEME_DIR/types/$MODE.json"
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

python3 - "$SRC" > "$HOME/pro/dotfiles/hypr/hyprlock-colors.conf" <<'PYEOF'
import json, sys

data = json.load(open(sys.argv[1]))
for k, v in data.items():
    if isinstance(v, str):
        if v.startswith("#"):
            print(f"${k} = 0xff{v[1:]}")
        elif v.startswith("rgba(") or v.startswith("rgb("):
            print(f"${k} = {v}")
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

python3 - "$SRC" <<'PYEOF'
import json, sys

data = json.load(open(sys.argv[1]))
fg = data.get('fg', 'cdd6f4').replace('#', '')
fg_muted = data.get('fgMuted', 'a6adc8').replace('#', '')
accent = data.get('accent', '89b4fa').replace('#', '')
red = data.get('red', 'f38ba8').replace('#', '')
green = data.get('green', 'a6e3a1').replace('#', '')

fish_theme = f"""# Dynamic Fish shell colors from apply-theme.sh

set -g fish_color_normal {fg}
set -g fish_color_command {accent}
set -g fish_color_quote {green}
set -g fish_color_redirection {fg}
set -g fish_color_end {fg}
set -g fish_color_error {red}
set -g fish_color_param {fg}
set -g fish_color_comment {fg_muted}
set -g fish_color_match {accent}
set -g fish_color_selection {fg_muted}
set -g fish_color_search_match {accent}
set -g fish_color_operator {accent}
set -g fish_color_escape {accent}
set -g fish_color_autosuggestion {fg_muted}
set -g fish_color_cwd {accent}
set -g fish_color_accent {accent}
"""

with open("/home/moi/pro/dotfiles/fish/theme.fish", "w") as f:
    f.write(fish_theme)
PYEOF

python3 - "$SRC" <<'PYEOF'
import json, sys, os

src_file = sys.argv[1]
with open(src_file) as f:
    data = json.load(f)

bg = data.get('bg', '#000000')
bg_alt = data.get('bgAlt', '#1a1a2e')
fg = data.get('fg', '#ffffff')
fg_muted = data.get('fgMuted', '#8c8c8c')
accent = data.get('accent', '#3abff8')
red = data.get('red', '#ff5555')

# 1. Write GTK CSS Overrides
gtk_css = f"""@define-color theme_bg_color {bg};
@define-color theme_fg_color {fg};
@define-color theme_text_color {fg};
@define-color theme_selected_bg_color {accent};
@define-color theme_selected_fg_color {bg};
@define-color accent_color {accent};
@define-color accent_bg_color {accent};
@define-color accent_fg_color {bg};
@define-color window_bg_color {bg};
@define-color window_fg_color {fg};
@define-color view_bg_color {bg};
@define-color view_fg_color {fg};
@define-color headerbar_bg_color {bg};
@define-color headerbar_fg_color {fg};
@define-color card_bg_color {bg_alt};
@define-color card_fg_color {fg};
@define-color dialog_bg_color {bg};
@define-color dialog_fg_color {fg};
@define-color popover_bg_color {bg_alt};
@define-color popover_fg_color {fg};
@define-color sidebar_bg_color {bg};
@define-color sidebar_fg_color {fg};
"""

for version in ["gtk-3.0", "gtk-4.0"]:
    dir_path = os.path.expanduser(f"~/.config/{version}")
    os.makedirs(dir_path, exist_ok=True)
    with open(os.path.join(dir_path, "gtk.css"), "w") as f:
        f.write(gtk_css)

# 2. Write QT5/6 color schemes
def make_color_list(bg, bg_alt, fg, fg_muted, accent, disabled=False):
    fg_eff = fg_muted if disabled else fg
    accent_eff = fg_muted if disabled else accent
    
    items = [
        fg_eff,       # 0: WindowText
        bg,           # 1: Button
        bg_alt,       # 2: Light
        bg_alt,       # 3: Midlight
        bg,           # 4: Dark
        bg_alt,       # 5: Mid
        fg_eff,       # 6: Text
        fg_eff,       # 7: BrightText
        fg_eff,       # 8: ButtonText
        bg,           # 9: Base
        bg,           # 10: Window
        "#ff000000",  # 11: Shadow
        accent_eff,   # 12: Highlight
        bg,           # 13: HighlightedText
        accent_eff,   # 14: Link
        accent_eff,   # 15: LinkVisited
        bg_alt,       # 16: AlternateBase
        "#ff000000",  # 17: NoRole
        bg,           # 18: ToolTipBase
        fg_eff,       # 19: ToolTipText
        fg_muted,     # 20: PlaceholderText
        accent_eff    # 21: Accent
    ]
    
    res = []
    for item in items:
        clean = item.replace("#", "")
        if len(clean) == 6:
            res.append(f"#ff{clean}")
        elif len(clean) == 8:
            res.append(f"#{clean}")
        else:
            res.append("#ffffffff")
    return ", ".join(res)

active_list = make_color_list(bg, bg_alt, fg, fg_muted, accent, False)
inactive_list = make_color_list(bg, bg_alt, fg, fg_muted, accent, False)
disabled_list = make_color_list(bg, bg_alt, fg, fg_muted, accent, True)

qt_scheme = f"""[ColorScheme]
active_colors={active_list}
disabled_colors={disabled_list}
inactive_colors={inactive_list}
"""

for version in ["qt5ct", "qt6ct"]:
    dir_path = os.path.expanduser(f"~/.config/{version}/colors")
    os.makedirs(dir_path, exist_ok=True)
    with open(os.path.join(dir_path, "custom.conf"), "w") as f:
        f.write(qt_scheme)

# 3. Update qt5ct/qt6ct conf to load custom color scheme
for version in ["qt5ct", "qt6ct"]:
    conf_path = os.path.expanduser(f"~/.config/{version}/{version}.conf")
    lines = []
    has_appearance = False
    
    if os.path.exists(conf_path):
        with open(conf_path) as f:
            lines = f.readlines()
            
    appearance_index = -1
    for idx, line in enumerate(lines):
        if line.strip() == "[Appearance]":
            appearance_index = idx
            has_appearance = True
            break
            
    if not has_appearance:
        lines.append("[Appearance]\n")
        lines.append(f"color_scheme_path={os.path.expanduser(f'~/.config/{version}/colors/custom.conf')}\n")
        lines.append("custom_palette=true\n")
        lines.append("style=Fusion\n")
    else:
        keys = {
            "color_scheme_path": f"{os.path.expanduser(f'~/.config/{version}/colors/custom.conf')}",
            "custom_palette": "true",
            "style": "Fusion"
        }
        filtered_lines = []
        for idx, line in enumerate(lines):
            line_str = line.strip()
            if idx > appearance_index and line_str.startswith("["):
                filtered_lines.extend(lines[idx:])
                break
            if idx > appearance_index and any(line_str.startswith(k + "=") for k in keys):
                continue
            filtered_lines.append(line)
            
        for idx, line in enumerate(filtered_lines):
            if line.strip() == "[Appearance]":
                appearance_index = idx
                break
                
        for k, v in keys.items():
            filtered_lines.insert(appearance_index + 1, f"{k}={v}\n")
        lines = filtered_lines
        
    with open(conf_path, "w") as f:
        f.writelines(lines)
PYEOF



# Helper to update gsettings only if the value has changed
set_gsettings() {
    local schema="$1"
    local key="$2"
    local val="$3"
    local current
    current=$(gsettings get "$schema" "$key" 2>/dev/null | tr -d "'\"" || echo "")
    if [[ "$current" != "$val" ]]; then
        gsettings set "$schema" "$key" "$val" 2>/dev/null || true
    fi
}

MODE_TYPE=$(python3 -c "import json; print(json.load(open('$SRC'))['mode'])" 2>/dev/null || echo "dark")
if [[ "$MODE_TYPE" == "dark" ]]; then
    set_gsettings org.gnome.desktop.interface color-scheme 'prefer-dark'
    set_gsettings org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
else
    set_gsettings org.gnome.desktop.interface color-scheme 'prefer-light'
    set_gsettings org.gnome.desktop.interface gtk-theme 'Adwaita'
fi

# Set Catppuccin cursor theme based on mode (dark/light)
CURSOR_THEME="catppuccin-mocha-dark-cursors"
if [[ "$MODE_TYPE" == "light" ]]; then
    CURSOR_THEME="catppuccin-latte-light-cursors"
fi

# 2. Define GTK theme name
if [[ "$MODE_TYPE" == "dark" ]]; then
    THEME_NAME="Adwaita-dark"
    PREFER_DARK="1"
else
    THEME_NAME="Adwaita"
    PREFER_DARK="0"
fi

# Only update cursor on DBus/Hyprland if it actually changed to avoid system-wide mouse freeze lag
CURRENT_CURSOR=$(gsettings get org.gnome.desktop.interface gtk-cursor-theme 2>/dev/null | tr -d "'\"" || echo "")
if [[ "$CURRENT_CURSOR" != "$CURSOR_THEME" ]]; then
    # Update ~/.icons/default/index.theme
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$CURSOR_THEME
EOF

    # Update GTK settings.ini files (including new cursor)
    for version in "gtk-3.0" "gtk-4.0"; do
        mkdir -p "$HOME/.config/$version"
        cat > "$HOME/.config/$version/settings.ini" <<EOF
[Settings]
gtk-theme-name=$THEME_NAME
gtk-application-prefer-dark-theme=$PREFER_DARK
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=24
EOF
    done

    # Set via gsettings
    set_gsettings org.gnome.desktop.interface gtk-cursor-theme "$CURSOR_THEME"
    set_gsettings org.gnome.desktop.interface gtk-cursor-size 24

    # Set via hyprctl
    hyprctl setcursor "$CURSOR_THEME" 24 2>/dev/null || true
else
    # Cursor is already correct, but rewrite settings.ini to ensure GTK picks up dark/light theme properties
    for version in "gtk-3.0" "gtk-4.0"; do
        mkdir -p "$HOME/.config/$version"
        cat > "$HOME/.config/$version/settings.ini" <<EOF
[Settings]
gtk-theme-name=$THEME_NAME
gtk-application-prefer-dark-theme=$PREFER_DARK
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=24
EOF
    done
fi

echo "Tema: $MODE"
