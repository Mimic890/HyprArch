#!/bin/bash
# HyprVSCode custom setup script

read -p $'\e[36mУстановить кастом HyprVSCode? (y/n): \e[0m' install_vscode
if [[ "$install_vscode" =~ ^[Yy]$ ]]; then
    CONFIG_DIR="$HOME/.config/Code/User"
    SRC_DIR="$HOME/HyprArch/customs/vs-code/Code/User"
    EXT_FILE="$HOME/HyprArch/customs/vs-code/vscode-extensions.txt"

    mkdir -p "$CONFIG_DIR"

    for file in keybindings.json settings.json; do
        if [ -f "$CONFIG_DIR/$file" ]; then
            rm "$CONFIG_DIR/$file" >>"$HOME/HyprArch/log.txt" 2>&1
        fi
        if [ -f "$SRC_DIR/$file" ]; then
            cp "$SRC_DIR/$file" "$CONFIG_DIR/" >>"$HOME/HyprArch/log.txt" 2>&1
        else
            echo -e "\e[33mФайл $SRC_DIR/$file не найден, пропуск.\e[0m"
        fi
    done

		if ! command -v code &>/dev/null; then
				echo "❌ Команда 'code' не найдена. Убедись, что VS Code CLI доступен в PATH."
				exit 1
		fi

		if [ ! -f "$EXT_FILE" ]; then
				echo "❌ Файл $EXT_FILE не найден."
				exit 1
		fi

		echo "📦 Начинаю установку расширений из $EXT_FILE..."

		install_extension() {
				local ext="$1"
				if ! code --list-extensions | grep -q "^${ext}$"; then
						echo "➤ Устанавливаю: $ext"
						code --install-extension "$ext" >>"$HOME/HyprArch/log.txt" 2>&1 || echo "⚠️ Ошибка при установке $ext"
				else
						echo "✔ Уже установлено: $ext"
				fi
		}

		while IFS= read -r extension || [[ -n "$extension" ]]; do
				[[ -z "$extension" || "$extension" =~ ^# ]] && continue
				install_extension "$extension"
		done < "$EXT_FILE"

		echo "✅ Установка завершена."

	echo -e "\e[34mПропуск кастомизации HyprVSCode.\e[0m"
fi
