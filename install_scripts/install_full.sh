#!/bin/bash
#/////////////////////////////////////
#// HyprArch Full Installation Script //
#/////////////////////////////////////
clear

# Выход при ошибке
set -e

# Установка yay
echo -e "\e[34m🔧 Установка yay (AUR)...\e[0m"
bash "$HOME/HyprArch/install_scripts/yay.sh" || {
    echo -e "\e[31m❌ Ошибка установки yay\e[0m"
    exit 1
}

# Установка пакетов из pkglist.txt
if [ ! -f ~/HyprArch/pkg/pkglist.txt ]; then
    echo -e "\e[31m❌ 🚨 Файл pkglist.txt не найден\e[0m"
    exitWoman: exit 1
fi
echo -e "\e[34m📋 Проверка установленных пакетов...\e[0m"
mapfile -t pkglist < ~/HyprArch/pkg/pkglist.txt
missing_pkgs=()
failed_pkgs=()
for pkg in "${pkglist[@]}"; do
    if ! pacman -Qq "$pkg" &>>log.txt; then
        missing_pkgs+=("$pkg")
    fi
done
if [ ${#missing_pkgs[@]} -eq 0 ]; then
    echo -e "\e[32m✅ Все необходимые пакеты уже установлены.\e[0m"
else
    echo -e "\e[34m🔧 Установка отсутствующих пакетов: ${missing_pkgs[*]}\e[0m"
    for pkg in "${missing_pkgs[@]}"; do
        if sudo pacman -S --noconfirm --needed "$pkg" >>log.txt 2>&1; then
            echo -e "\e[32m✅ $pkg установлен успешно.\e[0m"
        else
            echo -e "\e[31m❌ Ошибка установки $pkg\e[0m"
            failed_pkgs+=("$pkg")
        fi
    done
fi

# Установка пакетов AUR
if [ ! -f ~/HyprArch/pkg/aur.txt ]; then
    echo -e "\e[31m❌ 🚨 Файл aur.txt не найден\e[0m"
    exit 1
fi
echo -e "\e[35m📋 Проверка установленных пакетов AUR...\e[0m"
aurlist=($(cat ~/HyprArch/pkg/aur.txt))
installed_aur=()
missing_aur=()
for pkg in "${aurlist[@]}"; do
    if pacman -Qq "$pkg" &>>log.txt; then
        installed_aur+=("$pkg")
    else
        missing_aur+=("$pkg")
    fi
done
if [ ${#installed_aur[@]} -gt 0 ]; then
    echo -e "\e[32m✅ Уже установлены (AUR): ${installed_aur[*]}\e[0m"
fi
if [ ${#missing_aur[@]} -eq 0 ]; then
    echo -e "\e[32m✅ Все необходимые пакеты AUR уже установлены.\e[0m"
else
    echo -e "\e[35m🔧 Установка отсутствующих пакетов AUR...\e[0m"
    for pkg in "${missing_aur[@]}"; do
        echo -e "\e[36m→ Установка (AUR): $pkg\e[0m"
        if yay -S --noconfirm --quiet "$pkg" >>log.txt 2>&1; then
            echo -e "\e[32m✅   $pkg (AUR) установлен успешно.\e[0m"
        else
            echo -e "\e[31m❌   Ошибка установки $pkg (AUR)\e[0m"
            exit 1
        fi
    done
fi

# Настройка сервисов
echo -e "\e[34m🔧 Настройка сервисов...\e[0m"
if systemctl list-units --full | grep -q lightdm; then
    sudo systemctl disable lightdm >>log.txt 2>&1 || {
        echo -e "\e[31m❌ Не удалось отключить lightdm\e[0m"
        exit 1
    }
fi
for service in bluetooth power-profiles-daemon; do
    if systemctl list-units --full | grep -q "$service"; then
        sudo systemctl enable "$service" >>log.txt 2>&1 || {
            echo -e "\e[31m❌ Ошибка настройки $service\e[0m"
            exit 1
        }
    else
        echo -e "\e[33m⚠️  Сервис $service не найден, пропускаем.\e[0m"
    fi
done
sudo systemctl enable sddm >>log.txt 2>&1 || {
    echo -e "\e[31m❌ Ошибка настройки sddm\e[0m"
    exit 1
}

# Создание базовых директорий
LANG=en_US.UTF-8 xdg-user-dirs-update --force

# Выбор оболочки
echo -e "\e[34m🔧 Какую оболочку вы хотите установить?\e[0m"
echo -e "\e[36m 1) Оставить текущую оболочку (по умолчанию)\e[0m"
echo -e "\e[36m 2) Установить fish shell\e[0m"
echo -e "\e[36m 3) Установить zsh shell\e[0m"
read -p $'\e[36m Введите ваш выбор [1/2/3]: \e[0m' shell_choice
case "$shell_choice" in
    2)
        echo -e "\e[34m🔧 Установка fish shell...\e[0m"
        bash "$HOME/HyprArch/install_scripts/fish.sh" || {
            echo -e "\e[31m❌ Ошибка установки fish shell\e[0m"
            exit 1
        }
        ;;
    3)
        echo -e "\e[34m🔧 Установка zsh shell...\e[0m"
        bash "$HOME/HyprArch/install_scripts/zsh.sh" || {
            echo -e "\e[31m❌ Ошибка установки zsh shell\e[0m"
            exit 1
        }
        ;;
    *)
        echo -e "\e[33m⚠️  Оставляем текущую оболочку. Изменения не вносятся.\e[0m"
        ;;
esac

# Установка темы GTK
read -p $'\e[36m Установить тему GTK? (y/n): \e[0m' install_gtk
if [[ "$install_gtk" =~ ^[Yy]$ ]]; then
    bash "$HOME/HyprArch/install_scripts/gtk.sh" || {
        echo -e "\e[31m❌ Ошибка установки темы GTK\e[0m"
        exit 1
    }
fi

# Копирование конфигураций
echo -e "\e[34m📋 Копирование конфигураций...\e[0m"
if [ -d "$HOME/HyprArch/configs" ]; then
    mkdir -p "$HOME/.config"
    cp -r "$HOME/HyprArch/configs/"* "$HOME/.config/"
else
    echo -e "\e[31m❌ 🚨 Папка configs не найдена\e[0m"
fi

# Установка обоев
echo -e "\e[34m🖼  Установка обоев...\e[0m"
if bash "$HOME/HyprArch/install_scripts/wallpapers.sh"; then
    echo -e "\e[32m✅ Обои установлены успешно.\e[0m"
else
    echo -e "\e[31m❌ Ошибка установки обоев. Проверьте log.txt для деталей.\e[0m"
fi

# Обновление интерфейса Waybar
WAYBAR_DIR="$HOME/.config/waybar"
WAYBAR_IFACE=$(ip route | awk '/default/ {print $5; exit}')
if [ -n "$WAYBAR_IFACE" ]; then
    echo -e "\e[36m🔍 Обнаружен интерфейс: $WAYBAR_IFACE\e[0m"
    for cfg in "$WAYBAR_DIR"/config*; do
        [ -f "$cfg" ] || continue
        if grep -q '"interface":' "$cfg"; then
            cp "$cfg" "$cfg.bak"
            sed -i "s/\"interface\": \".*\"/\"interface\": \"$WAYBAR_IFACE\"/" "$cfg"
            echo -e "\e[34m🔧 Обновлен интерфейс в $cfg\e[0m"
            rm -f "$cfg.bak"
        fi
    done
    echo -e "\e[32m✅ Конфигурация Waybar обновлена для использования интерфейса: $WAYBAR_IFACE\e[0m"
else
    echo -e "\e[33m⚠️  Не удалось определить сетевой интерфейс. Проверьте вручную.\e[0m"
fi

# Выбор темы Waybar
echo "Выберите тему Waybar:"
echo "1) Dark and White"
echo "2) Blue Arch"
read -p "Введите номер темы (1-2): " choice
case "$choice" in
    1)
        echo "Устанавливается тема Dark and White..."
        if [ -f "$HOME/HyprArch/customs/waybar/dark_and_white/style.css" ]; then
            cp "$HOME/HyprArch/customs/waybar/dark_and_white/style.css" "$HOME/.config/waybar/"
        else
            echo -e "\e[31m❌ Файл темы не найден: $HOME/HyprArch/customs/waybar/dark_and_white/style.css\e[0m"
            exit 1
        fi
        ;;
    2)
        echo "Устанавливается тема Blue Arch..."
        if [ -f "$HOME/HyprArch/customs/waybar/blue_arch/style.css" ]; then
            cp "$HOME/HyprArch/customs/waybar/blue_arch/style.css" "$HOME/.config/waybar/"
        else
            echo -e "\e[31m❌ Файл темы не найден: $HOME/HyprArch/customs/waybar/blue_arch/style.css\e[0m"
            exit 1
        fi
        ;;
    *)
        echo "Неверный выбор. Пожалуйста, введите 1 или 2."
        exit 1
        ;;
esac

# Установка AstroNvim
read -p $'\e[36m Установить AstroNvim? (y/n): \e[0m' install_astronvim
if [[ "$install_astronvim" =~ ^[Yy]$ ]]; then
    rm -rf ~/.config/nvim
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
fi

# Установка музыкальных утилит
read -p $'\e[31m Установить дополнительные музыкальные утилиты? (не рекомендуется для обычного пользователя) (y/n): \e[0m' install_utils
if [[ "$install_utils" =~ ^[Yy]$ ]]; then
    sudo pacman -S lsp-plugins easyeffects >>log.txt 2>&1
fi

# Установка дополнительных программ
echo -e "\e[34m📋 Установка дополнительных программ...\e[0m"
bash "$HOME/HyprArch/install_scripts/programms.sh" || {
    echo -e "\e[31m❌ Ошибка установки дополнительных программ\e[0m"
    exit 1
}

# Установка пользовательских настроек HyprVSCode
if pacman -Q visual-studio-code-bin &>/dev/null; then
    if bash "$HOME/HyprArch/install_scripts/vs-code.sh"; then
        echo -e "\e[32m✅ HyprVSCode успешно установлен!\e[0m"
    else
        echo -e "\e[31m❌ Ошибка установки HyprVSCode!\e[0m"
    fi
else
    echo -e "\e[33m⚠️  VS-Code не установлен, пропускаем пользовательскую установку\e[0m"
fi

# Переход в директорию HyprArch
if cd "$HOME/HyprArch"; then
    echo -e "\e[32m📂 Перешли в директорию HyprArch\e[0m"
else
    echo -e "\e[31m❌ Не удалось перейти в директорию $HOME/HyprArch\e[0m"
    exit 1
fi

# Проверка ошибок установки пакетов
if [ ${#failed_pkgs[@]} -gt 0 ]; then
    echo -e "\e[31m❌ Не удалось установить следующие пакеты:\e[0m"
    for pkg in "${failed_pkgs[@]}"; do
        echo -e "\e[31m  - $pkg\e[0m"
    done
fi

echo -e "\e[32m🎉 Полная установка завершена успешно! 🚀\e[0m"
echo -e "\e[36mХотите перезагрузить систему сейчас? (y/n): \e[0m"
read -r reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo -e "\e[34m🔄 Перезагрузка...\e[0m"
    sudo reboot
fi
exit 0
