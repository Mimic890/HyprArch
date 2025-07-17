#!/bin/bash

# question about blackarch
read -p "Добавить репозиторий blackarch? (Y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    curl -O https://blackarch.org/strap.sh ~/
    chmod +x ~/strap.sh
    sudo ~/strap.sh
    echo "Репозиторий blackarch добавлен."
    sudo rm ~/strap.sh
else
    echo "Репозиторий blackarch не добавлен."
fi

# Установка whiptail, если отсутствует
if ! command -v whiptail &> /dev/null; then
  echo -e "\e[34mУстановка whiptail...\e[0m"
  if ! sudo pacman -Sy --noconfirm whiptail >>"$HOME/HyprArch/log.txt" 2>&1; then
    echo -e "\e[31mОшибка установки whiptail.\e[0m"
    exit 1
  fi
fi

# Проверка наличия репозитория BlackArch
if ! grep -q "^\[blackarch\]" /etc/pacman.conf; then
  echo -e "\e[34mРепозиторий BlackArch не найден. Добавляем...\e[0m"
  if ! curl -s -O https://blackarch.org/strap.sh >>"$HOME/HyprArch/log.txt" 2>&1; then
    echo -e "\e[31mОшибка загрузки strap.sh.\e[0m"
    exit 1
  fi
  chmod +x strap.sh
  if ! sudo ./strap.sh >>"$HOME/HyprArch/log.txt" 2>&1; then
    echo -e "\e[31mОшибка выполнения strap.sh.\e[0m"
    rm -f strap.sh
    exit 1
  fi
  rm strap.sh
  if ! grep -q "^\[blackarch\]" /etc/pacman.conf; then
    echo -e "\e[31mНе удалось добавить репозиторий BlackArch.\e[0m"
    exit 1
  fi
else
  echo -e "\e[32mРепозиторий BlackArch уже настроен.\e[0m"
fi

# Синхронизация базы пакетов
echo -e "\e[34mОбновление базы пакетов...\e[0m"
if ! sudo pacman -Syy >>"$HOME/HyprArch/log.txt" 2>&1; then
  echo -e "\e[31mОшибка синхронизации базы пакетов.\e[0m"
  exit 1
fi

# Получение категорий BlackArch
CATEGORIES=$(pacman -Sg | grep '^blackarch-' | awk '{print $1}' | sort -u)

# Проверка наличия категорий
if [ -z "$CATEGORIES" ]; then
  echo -e "\e[31mНе удалось получить категории BlackArch.\e[0m"
  exit 1
fi

# Формирование массива для меню
CHOICE_ITEMS=(
  "blackarch-all" "Установить все инструменты BlackArch" OFF
)
for category in $CATEGORIES; do
  CHOICE_ITEMS+=("$category" "Категория BlackArch" OFF)
done

# Меню выбора категорий
CHOICES=$(whiptail --title "Установщик BlackArch" --checklist \
"Выберите категории для установки (ПРОБЕЛ — выбрать, TAB — переход):" 25 78 20 \
"${CHOICE_ITEMS[@]}" 3>&1 1>&2 2>&3)

# Проверка отмены
if [ $? -ne 0 ]; then
  echo -e "\e[33mУстановка отменена пользователем.\e[0m"
  exit 1
fi

# Преобразование выбора в массив
SELECTED=($CHOICES)

# Установка выбранных категорий с повторными попытками
for choice in "${SELECTED[@]}"; do
  category=$(echo "$choice" | tr -d '"')
  echo -e "\e[34mУстановка: $category\e[0m"
  retries=3
  while [ $retries -gt 0 ]; do
    if sudo pacman -S --noconfirm --needed "$category" 2>&1 | tee -a "$HOME/HyprArch/log.txt"; then
      echo -e "\e[32m$category установлен.\e[0m"
      break
    else
      echo -e "\e[31mОшибка установки $category. Осталось попыток: $retries\e[0m"
      ((retries--))
      sleep 5
      sudo pacman -Syy 2>&1 | tee -a "$HOME/HyprArch/log.txt"
    fi
  done
  if [ $retries -eq 0 ]; then
    echo -e "\e[31mНе удалось установить $category после всех попыток.\e[0m"
  fi
done

echo -e "\e[32mУстановка категорий BlackArch завершена.\e[0m"
exit 0
