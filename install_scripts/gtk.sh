#!/bin/bash

set -e

# .gtkrc-2.0
if [ -f "$HOME/.gtkrc-2.0" ]; then
    rm -f "$HOME/.gtkrc-2.0"
fi
cp "$HOME/HyprArch/customs/gtk/.gtkrc-2.0" "$HOME/"

# gtk-3.0
if [ -d "$HOME/.config/gtk-3.0" ]; then
    rm -rf "$HOME/.config/gtk-3.0"
fi
cp -r "$HOME/HyprArch/customs/gtk/gtk-3.0" "$HOME/.config/"

# gtk-4.0
if [ -d "$HOME/.config/gtk-4.0" ]; then
    rm -rf "$HOME/.config/gtk-4.0"
fi
cp -r "$HOME/HyprArch/customs/gtk/gtk-4.0" "$HOME/.config/"

# xsettingsd
if [ -d "$HOME/.config/xsettingsd" ] || [ -f "$HOME/.config/xsettingsd" ]; then
    rm -rf "$HOME/.config/xsettingsd"
fi
cp -r "$HOME/HyprArch/customs/gtk/xsettingsd" "$HOME/.config/"

echo -e "\e[32m✅ GTK theme installed successfully.\e[0m"
exit 0
