<h1 align="center">capsule-dots</h1>
<p align="center">Version 0.1</p>

<p align="center">
  A premium, dynamic Linux workspace setup inspired by the highly portable and versatile capsules of <b>Capsule Corp</b>. Built for <b>Hyprland</b> and driven by <b>Quickshell</b>.
</p>

<p align="center">
  💊 <i>All your desktop utilities packed into a single, morphing capsule.</i>
</p>

---

## Requirements

The following packages and dependencies must be installed on your system:

* **AUR Helper**: `paru` or `yay` (required for package installation check)
* **Compositor / Window Manager**: `hyprland`
* **Status Bar & Shell**: `quickshell`
* **Fonts**: `ttf-jetbrains-mono-nerd`
* **Terminal**: `ghostty`
* **Shell**: `fish`
* **System Utilities**:
  * `networkmanager` (provides `nmcli` for Wi-Fi management)
  * `pipewire` & `wireplumber` (for audio level and device tracking)
  * `upower` (for battery charge and status levels)
  * `libpulse` (provides `pactl` used by the visualizer)
  * `polkit` (required for system privilege authentication)
  * `playerctl` (optional, for media player backend support)
  * `python` (required to run script listings for themes/wallpapers/languages)
  * `gsettings-desktop-schemas` (for GTK theme and cursor application)
  * `qt5ct` & `qt6ct` (optional, to apply custom themes to Qt5/6 applications)
  * `cliphist` (for clipboard history tracking)

## Installation

> [!IMPORTANT]
> The repository **must** be cloned or moved to `~/pro/dotfiles` (i.e. `/home/YOUR_USER/pro/dotfiles`), as multiple scripts, themes, and configuration paths are hardcoded to this directory.

To clone the repository to the required location, install dependencies, and set up symlinks automatically:

```bash
# Create the parent directory if it does not exist
mkdir -p ~/pro

# Clone the repository into the exact folder
git clone https://github.com/moiCR/capsule-dots ~/pro/dotfiles
cd ~/pro/dotfiles

# Run the installer
chmod +x install.sh
./install.sh
```
