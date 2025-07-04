#!/bin/bash
# HyprVSCode custom setup script

read -p $'\e[36m📋 Install custom HyprVSCode? (y/n): \e[0m' install_vscode
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
            echo -e "\e[33m⚠️  File $SRC_DIR/$file not found, skipping.\e[0m"
        fi
    done

    if ! command -v code &>/dev/null; then
        echo -e "\e[31m❌ Command 'code' not found. Make sure VS Code CLI is in PATH.\e[0m"
        exit 1
    fi

    if [ ! -f "$EXT_FILE" ]; then
        echo -e "\e[31m❌ File $EXT_FILE not found.\e[0m"
        exit 1
    fi

    echo -e "\e[34m🔧 Installing extensions from $EXT_FILE...\e[0m"

    install_extension() {
        local ext="$1"
        if ! code --list-extensions | grep -q "^${ext}$"; then
            echo -e "\e[36m→ Installing: $ext\e[0m"
            code --install-extension "$ext" >>"$HOME/HyprArch/log.txt" 2>&1 || echo -e "\e[31m❌ Error installing $ext\e[0m"
        else
            echo -e "\e[32m✅ Already installed: $ext\e[0m"
        fi
    }

    while IFS= read -r extension || [[ -n "$extension" ]]; do
        [[ -z "$extension" || "$extension" =~ ^# ]] && continue
        install_extension "$extension"
    done < "$EXT_FILE"

    echo -e "\e[32m✅ Extensions installation complete.\e[0m"

else
    echo -e "\e[33m⚠️  Skipping HyprVSCode customization.\e[0m"
fi
