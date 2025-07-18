#    ___           __
#   / _ \___  ____/ /__
#  / // / _ \/ __/  '_/
# /____/\___/\__/_/\_\
#
config="$HOME/.config/gtk-4.0/settings.ini"
killall nwg-dock-hyprland
sleep 0.5
prefer_dark_theme="$(grep 'gtk-application-prefer-dark-theme' "$config" | sed 's/.*\s*=\s*//')"
style="style.css"
nwg-dock-hyprland -i 40 -w 10 -mb 3 -ml 10 -mr 10 -x -s $style -c  "wofi --show drun"
