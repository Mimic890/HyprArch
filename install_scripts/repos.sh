#!/bin/bash
# Add multilib
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    echo "Репозиторий multilib добавлен."
else
    echo "Репозиторий multilib уже присутствует."
fi
exit 0
