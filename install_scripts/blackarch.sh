#!/bin/bash

mkdir -p "$HOME/HyprArch"

# 🔧 Installing whiptail
if ! command -v whiptail &> /dev/null; then
  echo -e "\e[34m🔧 Installing whiptail...\e[0m"
  sudo pacman -Sy --noconfirm whiptail >>"$HOME/HyprArch/log.txt" 2>&1
fi

# 🛡️ Проверка установленности BlackArch
if ! grep -q "\[blackarch\]" /etc/pacman.conf; then
  echo -e "\e[34m🛠️  BlackArch не найден. Устанавливаем репозиторий...\e[0m"
  curl -O https://blackarch.org/strap.sh >>"$HOME/HyprArch/log.txt" 2>&1
  chmod +x strap.sh
  sudo ./strap.sh >>"$HOME/HyprArch/log.txt" 2>&1
  rm strap.sh
else
  echo -e "\e[32m✅ BlackArch репозиторий уже добавлен.\e[0m"
fi

# 🔧 Проверка blackarch CLI
if ! command -v blackarch &> /dev/null; then
  echo -e "\e[31m❌ Утилита 'blackarch' не найдена. Что-то пошло не так при установке.\e[0m"
  exit 1
fi

# 🗂️ Получение категорий через blackarch -l
CATEGORIES=$(blackarch -l | grep -E '^blackarch-[a-z0-9_-]+$' | sort -u)

# 🧩 Массив с blackarch-all и всеми категориями
CHOICE_ITEMS=(
  "blackarch-all" "Установить все инструменты" OFF
)

for category in $CATEGORIES; do
  CHOICE_ITEMS+=("$category" "Категория BlackArch" OFF)
done

# 🧾 Меню выбора категорий
CHOICES=$(whiptail --title "BlackArch Installer" --checklist \
"Выберите, что установить (SPACE — выбрать, TAB — переход):" 25 78 20 \
"${CHOICE_ITEMS[@]}" 3>&1 1>&2 2>&3)

# Проверка отмены
if [ $? -ne 0 ]; then
  echo -e "\e[33m⚠️  Установка отменена пользователем.\e[0m"
  exit 1
fi

# Преобразование в массив
SELECTED=($CHOICES)

# 🔧 Установка выбранных категорий
for choice in "${SELECTED[@]}"; do
  category=$(echo "$choice" | tr -d '"')
  echo -e "\e[34m➡️  Устанавливаю: $category\e[0m"
  sudo pacman -S --noconfirm "$category" >>"$HOME/HyprArch/log.txt" 2>&1 && \
    echo -e "\e[32m✅ $category установлен.\e[0m" || \
    echo -e "\e[31m❌ Ошибка установки $category.\e[0m"
done

echo -e "\e[32m✅ Установка завершена.\e[0m"
exit 0
