#!/bin/bash

# Установка whiptail
if ! command -v whiptail &> /dev/null; then
  echo "Устанавливаю whiptail..."
  sudo pacman -Sy --noconfirm whiptail
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
  sudo pacman -Sy --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git
  cd yay && makepkg -si --noconfirm
  cd .. && rm -rf yay
fi

# Установка выбранных программ
for choice in "${SELECTED[@]}"; do
  case $choice in
    "\"Telegram\"")
      sudo pacman -S --noconfirm telegram-desktop
    ;;
    "\"Steam\"")
      sudo pacman -S --noconfirm steam
    ;;
    "\"OBS Studio\"")
      yay -S --noconfirm wlroots obs-studio
    ;;
    "\"Discord\"")
      sudo pacman -S --noconfirm discord
    ;;
    "\"Veracrypt\"")
      sudo pacman -S --noconfirm veracrypt
    ;;
    "\"VS Code\"")
      yay -S --noconfirm visual-studio-code-bin
    ;;
    "\"Spotify\"")
      yay -S --noconfirm spotify
    ;;
    "\"Obsidian\"")
      yay -S --noconfirm obsidian
    ;;
    "\"Yandex Music\"")
      yay -S --noconfirm yandex-music
    ;;
    "\"Nekoray\"")
      yay -S --noconfirm nekoray-bin
    ;;
  esac
done

echo "✅ Установка завершена."
