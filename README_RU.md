# HyprArch
## [README_EN](README.md)
### Установка одной строчкой
```
cd ~/ && git clone https://github.com/Mimic890/HyprArch.git && cd ~/HyprArch && chmod +x Install.sh && ./Install.sh
```

## Hyprland Keybinds
### Базовые Keybindings
| Действие                      | Keybind         |
|-------------------------------|-----------------|
| Открыть терминал (Kitty)         | SUPER + R       |
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
### CLI Утилты
| Tool    | Keybind             |
|---------|---------------------|
| btop    | SUPER + SHIFT + B   |
| cava    | SUPER + SHIFT + C   |
| htop    | SUPER + SHIFT + H   |
| nmtui   | SUPER + SHIFT + N   |
---
### Управление окнами
- Swap split mode: `SUPER + K`
- Toggle split orientation: `SUPER + J`
- Focus movement: `SUPER + Arrow Keys`
- Resize window: `SUPER + SHIFT + Arrow Keys`
- Swap window position: `SUPER + ALT + Arrow Keys`
---
### Управление рабочими столами
- Change workspace: `SUPER + [1–8]`
- Move window to workspace: `SUPER + SHIFT + [1–8]`
- Next/Previous workspace: `SUPER + Tab / SUPER + SHIFT + Tab`
- Scroll to switch workspace: `SUPER + Mouse Wheel`
- Toggle special workspace: `SUPER + S`
- Move window to special workspace: `SUPER + SHIFT + S`
---
### Управление мышью
- Move window: `SUPER + Left Click`
- Resize window: `SUPER + Right Click`
---
### Скриншоты
- Fullscreen: `SUPER + Print`
- Area selection: `SUPER + SHIFT + Print`
---
### Изменение яркости
- Decrease: `XF86MonBrightnessDown`
- Increase: `XF86MonBrightnessUp`
---
### Управление аудио
- Volume Up/Down: `XF86AudioRaiseVolume / XF86AudioLowerVolume`
- Mute Output: `XF86AudioMute`
- Mute Microphone: `XF86AudioMicMute`
---
### Media Keys (via `playerctl`)
- Next Track: `XF86AudioNext`
- Previous Track: `XF86AudioPrev`
- Play/Pause: `XF86AudioPlay` or `XF86AudioPause`
---
### Полезные команды hyprland
```bash
hyprctl clients					    # Посмотреть открытые окна и их параметры
hyprctl devices					    # Посмотреть подключенные девайсы (клавиатура, мышь и т. д.)
hyprctl getoption -a                # Проверка ошибок конфигурации (проблемы с разбором и т. д.)
hyprctl binds						# Показать все текущие настройки клавиш
hyprctl workspaces                    # Показать информацию о рабочих пространствах
hyprctl monitors                    # Показать текущую настройку монитора
hyprctl reload                        # Перезагрузить конфигурацию Hyprland (после редактирования ~/.config/hypr/hyprland.conf)
hyprctl dispatch exec «hyprctl reload»    # Принудительно переприменить расположение мониторов и конфигурацию
hyprctl activewindow                # Показать активные окна в виде дерева (полезно для обзора расположения окон)
hyprctl rules                        # Перечислить все доступные правила для окон
hyprctl animations                    # Вручную запустить анимацию (полезно для отладки)
