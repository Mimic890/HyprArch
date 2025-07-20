 #----------------#
 # HyprArch Dock #
#---------------#
config="$HOME/.config/gtk-4.0/settings.ini"
killall nwg-dock-hyprland
sleep 0.5
prefer_dark_theme="$(grep 'gtk-application-prefer-dark-theme' "$config" | sed 's/.*\s*=\s*//')"
style="style.css"

# Start command
nwg-dock-hyprland -i 40 -w 10 -mb 3 -ml 3 -mr 3 -x -p "left" -nolauncher -s $style -c  "wofi --show drun"

# -a <string> -- Alignment in full width/height: "start", "center", or "end" (default "center")
# -c <string> -- Command assigned to the launcher button (default "nwg-drawer")
# -d -- Auto-hide: show dock when hotspot hovered, close when left or a button clicked
# -debug -- Turn on debug messages
# -f -- Take full screen width/height
# -g <string> -- Quote-delimited, space-separated class list to ignore in the dock
# -hd <int> -- Hotspot delay [ms]; smaller values mean faster mouse pointer response to show dock; set 0 to disable (default 20)
# -hl <string> -- Hotspot layer: "overlay" or "top" (default "overlay")
# -i <int> -- Icon size (default 48)
# -ico <string> -- Alternative name or path for the launcher icon
# -iw <string> -- Ignore running applications on these workspaces based on workspace name or ID, e.g., "special,10"
# -l <string> -- Layer: "overlay", "top", or "bottom" (default "overlay")
# -lp <string> -- Launcher button position: "start" or "end" (default "end")
# -m -- Allow multiple instances of the dock (skip lock file check)
# -mb <int> -- Margin bottom
# -ml <int> -- Margin left
# -mr <int> -- Margin right
# -mt <int> -- Margin top
# -nolauncher -- Don't show the launcher button
# -o <string> -- Name of output to display the dock on
# -p <string> -- Position: "bottom", "top", "left", or "right" (default "bottom")
# -r -- Leave program resident, but without hotspot
# -s <string> -- Styling: CSS file name (default "style.css")
# -v -- Display version information
# -w <int> -- Number of workspaces in use (default 10)
# -x -- Set exclusive zone: move other windows aside; overrides the "-l" argument
