#!/bin/bash
# filepath: /home/mimic/HyprArch/add_repos.sh

# Add multilib
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    echo "Репозиторий multilib добавлен."
else
    echo "Репозиторий multilib уже присутствует."
fi

# question about blackarch
read -p "Добавить репозиторий blackarch? (Y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    curl -O https://blackarch.org/strap.sh
    chmod +x strap.sh
    sudo ./strap.sh
    echo "Репозиторий blackarch добавлен."
    sudo rm strap.sh
else
    echo "Репозиторий blackarch не добавлен."
fi
