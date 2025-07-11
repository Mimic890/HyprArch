#!/bin/bash

set -e

echo -e "\e[34m🔧 Installing GTK theme...\e[0m"
sudo pacman -S --noconfirm gtk4 gtk3 nwg-look >>"$HOME/HyprArch/log.txt" 2>&1

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
    sudo rm -rf "/usr/share/themes/Breeze-Dark" >>"$HOME/HyprArch/log.txt" 2>&1
fi
sudo cp -r "$HOME/HyprArch/customs/gtk/Breeze-Dark" "/usr/share/themes/" >>"$HOME/HyprArch/log.txt" 2>&1

echo -e "\e[32m✅ GTK theme installed successfully.\e[0m"
exit 0
