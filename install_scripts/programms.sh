#!/bin/bash

# Installing whiptail
if ! command -v whiptail &> /dev/null; then
  echo -e "\e[34mInstalling whiptail...\e[0m"
  sudo pacman -Sy --noconfirm whiptail >>"$HOME/HyprArch/log.txt" 2>&1
fi

# Program selection menu
CHOICES=$(whiptail --title "" --checklist \
"Select the programs you want to install (SPACE — select, TAB — move):" 25 78 15 \
"Telegram" "messenger" OFF \
"Steam" "game platform" OFF \
"OBS Studio" "screen recording and streaming" OFF \
"Discord" "voice and text chat" OFF \
"Veracrypt" "disk encryption" OFF \
"Foliate" "books and pdf reader" OFF \
"Motrix" "download manager" OFF \
"GIMP" "image editor" OFF \
"LibreOffice" "office suite" OFF \
"VS Code" "(AUR)(Official)" OFF \
"Spotify" "(AUR)(Official)" OFF \
"Obsidian" "(AUR)(Official)" OFF \
"Yandex Music" "(AUR)" OFF \
3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
  echo -e "\e[33mInstallation cancelled by user.\e[0m"
  exit 1
fi

# Convert the selection to an array
SELECTED=($CHOICES)

# Install yay if not already installed
if ! command -v yay &>/dev/null; then
  echo -e "\e[34myay not found, installing...\e[0m"
  sudo pacman -Sy --needed --noconfirm git base-devel >>"$HOME/HyprArch/log.txt" 2>&1
  git clone https://aur.archlinux.org/yay.git >>"$HOME/HyprArch/log.txt" 2>&1
  cd yay && makepkg -si --noconfirm >>"$HOME/HyprArch/log.txt" 2>&1
  cd .. && rm -rf yay >>"$HOME/HyprArch/log.txt" 2>&1
fi

# Installing selected programs
for choice in "${SELECTED[@]}"; do
  case $choice in
    "\"Telegram\"")
      sudo pacman -S --noconfirm telegram-desktop >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mTelegram installed.\e[0m" || echo -e "\e[31m❌ Telegram install failed.\e[0m"
    ;;
    "\"Steam\"")
      sudo pacman -S --noconfirm steam >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mSteam installed.\e[0m" || echo -e "\e[31m❌ Steam install failed.\e[0m"
    ;;
    "\"OBS Studio\"")
      yay -S --noconfirm wlroots obs-studio >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mOBS Studio installed.\e[0m" || echo -e "\e[31m❌ OBS Studio install failed.\e[0m"
    ;;
    "\"Discord\"")
      sudo pacman -S --noconfirm discord >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mDiscord installed.\e[0m" || echo -e "\e[31m❌ Discord install failed.\e[0m"
    ;;
    "\"Veracrypt\"")
      sudo pacman -S --noconfirm veracrypt >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mVeracrypt installed.\e[0m" || echo -e "\e[31m❌ Veracrypt install failed.\e[0m"
    ;;
    "\"Foliate\"")
      sudo pacman -S --noconfirm foliate >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mFoliate installed.\e[0m" || echo -e "\e[31m❌ Foliate install failed.\e[0m"
    ;;
    "\"Motrix\"")
      yay -S --noconfirm motrix-bin >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mMotrix installed.\e[0m" || echo -e "\e[31m❌ Motrix install failed.\e[0m"
    ;;
    "\"GIMP\"")
      sudo pacman -S --noconfirm gimp >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mGIMP installed.\e[0m" || echo -e "\e[31m❌ GIMP install failed.\e[0m"
    ;;
    "\"LibreOffice\"")
      sudo pacman -S --noconfirm libreoffice-fresh >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mLibreOffice installed.\e[0m" || echo -e "\e[31m❌ LibreOffice install failed.\e[0m"
    ;;
    "\"VS Code\"")
      yay -S --noconfirm visual-studio-code-bin >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mVS Code installed.\e[0m" || echo -e "\e[31m❌ VS Code install failed.\e[0m"
    ;;
    "\"Spotify\"")
      yay -S --noconfirm spotify >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mSpotify installed.\e[0m" || echo -e "\e[31m❌ Spotify install failed.\e[0m"
    ;;
    "\"Obsidian\"")
      yay -S --noconfirm obsidian >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mObsidian installed.\e[0m" || echo -e "\e[31m❌ Obsidian install failed.\e[0m"
    ;;
    "\"Yandex Music\"")
      yay -S --noconfirm yandex-music >>"$HOME/HyprArch/log.txt" 2>&1 && \
      echo -e "\e[32mYandex Music installed.\e[0m" || echo -e "\e[31m❌ Yandex Music install failed.\e[0m"
    ;;
  esac
done

echo -e "\e[32mInstallation complete.\e[0m"
exit 0
