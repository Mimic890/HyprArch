#!/bin/bash

set -e

echo -e "\e[34m🔧 Installing GTK theme...\e[0m"

# Install packages
if ! pacman -Qi gtk4 &>/dev/null || ! pacman -Qi gtk3 &>/dev/null || ! pacman -Qi nwg-look &>/dev/null; then
    sudo pacman -S --noconfirm gtk4 gtk3 nwg-look >>"$HOME/HyprArch/log.txt" 2>&1
else
    echo "GTK4, GTK3, and nwg-look already installed."
fi

# .gtkrc-2.0
if [ -f "$HOME/.gtkrc-2.0" ]; then
    rm -f "$HOME/.gtkrc-2.0" >>"$HOME/HyprArch/log.txt" 2>&1
fi
cp "$HOME/HyprArch/customs/gtk/.gtkrc-2.0" "$HOME/" >>"$HOME/HyprArch/log.txt" 2>&1

# gtk-3.0
if [ -d "$HOME/.config/gtk-3.0" ]; then
    rm -rf "$HOME/.config/gtk-3.0" >>"$HOME/HyprArch/log.txt" 2>&1
fi
cp -r "$HOME/HyprArch/customs/gtk/gtk-3.0" "$HOME/.config/" >>"$HOME/HyprArch/log.txt" 2>&1

# gtk-4.0
if [ -d "$HOME/.config/gtk-4.0" ]; then
    rm -rf "$HOME/.config/gtk-4.0" >>"$HOME/HyprArch/log.txt" 2>&1
fi
cp -r "$HOME/HyprArch/customs/gtk/gtk-4.0" "$HOME/.config/" >>"$HOME/HyprArch/log.txt" 2>&1

# xsettingsd
if [ -d "$HOME/.config/xsettingsd" ] || [ -f "$HOME/.config/xsettingsd" ]; then
    rm -rf "$HOME/.config/xsettingsd" >>"$HOME/HyprArch/log.txt" 2>&1
fi
cp -r "$HOME/HyprArch/customs/gtk/xsettingsd" "$HOME/.config/" >>"$HOME/HyprArch/log.txt" 2>&1

# Breeze-Dark theme
if [ -d "/usr/share/themes/Breeze-Dark" ] || [ -f "/usr/share/themes/Breeze-Dark" ]; then
    if sudo rm -rf "/usr/share/themes/Breeze-Dark" >>"$HOME/HyprArch/log.txt" 2>&1; then
        echo "Removed old Breeze-Dark theme."
    else
        echo "Warning: failed to remove old Breeze-Dark theme."
    fi
fi
if sudo cp -r "$HOME/HyprArch/customs/gtk/Breeze-Dark" "/usr/share/themes/" >>"$HOME/HyprArch/log.txt" 2>&1; then
    echo "Installed Breeze-Dark theme."
else
    echo "Warning: failed to install Breeze-Dark theme."
fi

# Check for gsettings
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "Breeze-Dark"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
else
    echo "gsettings not found. Skipping GNOME theme settings."
fi

echo -e "\e[32m✅ GTK theme installed successfully.\e[0m"
exit 0
