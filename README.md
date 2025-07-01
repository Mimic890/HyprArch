# HyprArch
### Installation command
```
cd ~/ && git clone https://github.com/Mimic890/HyprArch.git && cd ~/HyprArch && chmod +x Install.sh && ./Install.sh
```

## Hyprland Keybinds
### Base Key Binds
| Action                         | Keybind         |
|-------------------------------|-----------------|
| Open Terminal (Kitty)         | SUPER + R       |
| Open App Launcher (Wofi)      | SUPER + D       |
| Kill Focused Window           | SUPER + Q       |
| Toggle Floating Window        | SUPER + V       |
| Exit Hyprland                 | SUPER + SHIFT + R |
| File Manager (Thunar)         | SUPER + E       |
| Open Telegram                 | SUPER + T       |
| Open Blueman Manager          | SUPER + B       |
| Open Pavucontrol              | SUPER + P       |
| Open VS Code                  | SUPER + C       |
| Open Firefox                  | SUPER + F       |
| Open Nekoray                  | SUPER + K       |
| Open Yandex Music             | SUPER + M       |
| Open Motrix                   | SUPER + Y       |
| Open Obsidian                 | SUPER + O       |
| Toggle Notifications (swaync) | SUPER + N       |
| Color Picker (Hyprpicker)     | SUPER + I       |
| Lock Screen (Hyprlock)        | SUPER + L       |
| Show Logout Menu (wlogout)    | SUPER + SHIFT + Q |
---
### CLI Utilities in Terminal
| Tool    | Keybind             |
|---------|---------------------|
| btop    | SUPER + SHIFT + B   |
| cava    | SUPER + SHIFT + C   |
| htop    | SUPER + SHIFT + H   |
| nmtui   | SUPER + SHIFT + N   |
---
### Window Management
- Swap split mode: `SUPER + K`
- Toggle split orientation: `SUPER + J`
- Focus movement: `SUPER + Arrow Keys`
- Resize window: `SUPER + SHIFT + Arrow Keys`
- Swap window position: `SUPER + ALT + Arrow Keys`
---
### Workspace Management
- Change workspace: `SUPER + [1–8]`
- Move window to workspace: `SUPER + SHIFT + [1–8]`
- Next/Previous workspace: `SUPER + Tab / SUPER + SHIFT + Tab`
- Scroll to switch workspace: `SUPER + Mouse Wheel`
- Toggle special workspace: `SUPER + S`
- Move window to special workspace: `SUPER + SHIFT + S`
---
### Mouse Controls
- Move window: `SUPER + Left Click`
- Resize window: `SUPER + Right Click`
---
### Screenshots
- Fullscreen: `SUPER + Print`
- Area selection: `SUPER + SHIFT + Print`
---
### Brightness Control
- Decrease: `XF86MonBrightnessDown`
- Increase: `XF86MonBrightnessUp`
---
### Audio Control
- Volume Up/Down: `XF86AudioRaiseVolume / XF86AudioLowerVolume`
- Mute Output: `XF86AudioMute`
- Mute Microphone: `XF86AudioMicMute`
---
### Media Keys (via `playerctl`)
- Next Track: `XF86AudioNext`
- Previous Track: `XF86AudioPrev`
- Play/Pause: `XF86AudioPlay` or `XF86AudioPause`
---
### Useful Commands
```bash
hyprctl clients					# View open windows and their parameters
hyprctl devices					# Show input devices (keyboard, mouse, etc.)
hyprctl getoption -a				# Check for config errors (parsing issues etc.)
hyprctl binds						# Show all current keybinds
hyprctl workspaces					# Show information about workspaces
hyprctl monitors					# Show current monitor setup
hyprctl reload						# Reload Hyprland config (after editing ~/.config/hypr/hyprland.conf)
hyprctl dispatch exec "hyprctl reload"	# Force reapply monitor layout and config
hyprctl activewindow				# Show active windows in tree format (useful for tiling layout overview)
hyprctl rules						# List all available window rules applied
hyprctl animations					# Manually trigger animations (useful for debugging)
