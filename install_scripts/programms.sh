#!/bin/bash

# Установка whiptail
if ! command -v whiptail &> /dev/null; then
  echo "Устанавливаю whiptail..."
  sudo pacman -Sy --noconfirm whiptail >>"$HOME/HyprArch/log.txt" 2>&1
fi

# Меню выбора программ
CHOICES=$(whiptail --title "Дополнительные программы" --checklist \
"Выберите программы, которые вы хотите установить (ПРОБЕЛ — выбрать, TAB — переход):" 25 78 15 \
"Telegram" "" OFF \
"Steam" "" OFF \
"OBS Studio" "" OFF \
"Discord" "" OFF \
"Veracrypt" "" OFF \
"VS Code" "(AUR)" OFF \
"Spotify" "(AUR)" OFF \
"Obsidian" "(AUR)" OFF \
"Yandex Music" "(AUR)" OFF \
"Nekoray" "(AUR)" OFF \
3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  echo "Установка отменена пользователем."
  exit 1
fi

# Преобразуем выбор в массив
SELECTED=($CHOICES)

# Установка yay, если не установлен
if ! command -v yay &>/dev/null; then
  echo "yay не найден, устанавливаю..."
  sudo pacman -Sy --needed --noconfirm git base-devel >>"$HOME/HyprArch/log.txt" 2>&1
  git clone https://aur.archlinux.org/yay.git >>"$HOME/HyprArch/log.txt" 2>&1
  cd yay && makepkg -si --noconfirm >>"$HOME/HyprArch/log.txt" 2>&1
  cd .. && rm -rf yay >>"$HOME/HyprArch/log.txt" 2>&1
fi

# Установка выбранных программ
for choice in "${SELECTED[@]}"; do
  case $choice in
    "\"Telegram\"")
      sudo pacman -S --noconfirm telegram-desktop >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"Steam\"")
      sudo pacman -S --noconfirm steam >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"OBS Studio\"")
      yay -S --noconfirm wlroots obs-studio >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"Discord\"")
      sudo pacman -S --noconfirm discord >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"Veracrypt\"")
      sudo pacman -S --noconfirm veracrypt >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"VS Code\"")
      yay -S --noconfirm visual-studio-code-bin >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"Spotify\"")
      yay -S --noconfirm spotify >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"Obsidian\"")
      yay -S --noconfirm obsidian >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"Yandex Music\"")
      yay -S --noconfirm yandex-music >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
    "\"Nekoray\"")
      yay -S --noconfirm nekoray-bin >>"$HOME/HyprArch/log.txt" 2>&1
    ;;
  esac
done

echo "✅ Установка завершена."
