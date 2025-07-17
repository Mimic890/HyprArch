#!/bin/bash

# Создание директории для логов
mkdir -p "$HOME/HyprArch"

# Установка whiptail, если отсутствует
if ! command -v whiptail &> /dev/null; then
  echo -e "\e[34m🔧 Установка whiptail...\e[0m"
  if ! sudo pacman -Sy --noconfirm whiptail >>"$HOME/HyprArch/log.txt" 2>&1; then
    echo -e "\e[31m❌ Ошибка установки whiptail.\e[0m"
    exit 1
  fi
fi

# Проверка наличия репозитория BlackArch
if ! grep -q "^\[blackarch\]" /etc/pacman.conf; then
  echo -e "\e[34m🛠 Репозиторий BlackArch не найден. Добавляем...\e[0m"
  if ! curl -s -O https://blackarch.org/strap.sh >>"$HOME/HyprArch/log.txt" 2>&1; then
    echo -e "\e[31m❌ Ошибка загрузки strap.sh.\e[0m"
    exit 1
  fi
  chmod +x strap.sh
  if ! sudo ./strap.sh >>"$HOME/HyprArch/log.txt" 2>&1; then
    echo -e "\e[31m❌ Ошибка выполнения strap.sh.\e[0m"
    rm -f strap.sh
    exit 1
  fi
  rm strap.sh
  if ! grep -q "^\[blackarch\]" /etc/pacman.conf; then
    echo -e "\e[31m❌ Не удалось добавить репозиторий BlackArch.\e[0m"
    exit 1
  fi
else
  echo -e "\e[32m✅ Репозиторий BlackArch уже настроен.\e[0m"
fi

# Синхронизация базы пакетов
echo -e "\e[34m🔄 Обновление базы пакетов...\e[0m"
if ! sudo pacman -Syy >>"$HOME/HyprArch/log.txt" 2>&1; then
  echo -e "\e[31m❌ Ошибка синхронизации базы пакетов.\e[0m"
  exit 1
fi

# Получение категорий BlackArch
CATEGORIES=$(pacman -Sg | grep '^blackarch-' | awk '{print $1}' | sort -u)

# Проверка наличия категорий
if [ -z "$CATEGORIES" ]; then
  echo -e "\e[31m❌ Не удалось получить категории BlackArch.\e[0m"
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
  echo -e "\e[33m⚠️ Установка отменена пользователем.\e[0m"
  exit 1
fi

# Преобразование выбора в массив
SELECTED=($CHOICES)

# Установка выбранных категорий с повторными попытками
for choice in "${SELECTED[@]}"; do
  category=$(echo "$choice" | tr -d '"')
  echo -e "\e[34m➡️ Установка: $category\e[0m"
  retries=3
  while [ $retries -gt 0 ]; do
    if sudo pacman -S --noconfirm --needed "$category" 2>&1 | tee -a "$HOME/HyprArch/log.txt"; then
      echo -e "\e[32m✅ $category установлен.\e[0m"
      break
    else
      echo -e "\e[31m❌ Ошибка установки $category. Осталось попыток: $retries\e[0m"
      ((retries--))
      sleep 5
      sudo pacman -Syy 2>&1 | tee -a "$HOME/HyprArch/log.txt"
    fi
  done
  if [ $retries -eq 0 ]; then
    echo -e "\e[31m❌ Не удалось установить $category после всех попыток.\e[0m"
  fi
done

echo -e "\e[32m✅ Установка категорий BlackArch завершена.\e[0m"
exit 0
