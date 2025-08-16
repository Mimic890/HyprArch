#!/bin/bash
set -e

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"

if ! command -v rsync &>/dev/null; then
    echo -e "${Y}'rsync' is not installed. Installing via pacman...${E}"
    if ! command -v sudo &>/dev/null; then
        echo -e "${R}'sudo' is not available. Please install rsync manually.${E}"
        exit 1
    fi
    echo -e "${B}Updating pacman database...${E}"
    sudo pacman -Sy --noconfirm
    echo -e "${B}⬇ Installing rsync...${E}"
    sudo pacman -S --noconfirm rsync || {
        echo -e "${R}Failed to install rsync. Exiting.${E}"
        exit 1
    }
    echo -e "${G}rsync installed successfully.${E}"
fi

BACKUP_DIR="$HOME/.config/hyprarch/backups"
TEMP_DIR="$(mktemp -d)"
TIMESTAMP="$(date +"%d-%m_%H-%M")"
ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"

CONFIG_SRC="$HOME/.config"
GRUB_SRC="/boot/grub/themes"
SDDM_SRC="/usr/share/sddm/themes"

mkdir -p "$BACKUP_DIR"

echo -e "${B}Available backups:${E}"
mapfile -t archives < <(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | sort -r)

if [ ${#archives[@]} -eq 0 ]; then
    echo -e "${Y}— No backups found.${E}"
else
    for i in "${!archives[@]}"; do
        fname=$(basename "${archives[$i]}")
        echo -e "${Y}$i)${E} $fname"
    done
fi

echo
read -p $'\e[34mDo you want to [s]kip, [r]estore or [c]reate a new backup? (s/r/c): \e[0m' choice

case "$choice" in
    [Ss])
        echo -e "${Y}Skipping backup.${E}"
        ;;
    [Rr])
        if [ ${#archives[@]} -eq 0 ]; then
            echo -e "${R}No backups available to restore.${E}"
            exit 1
        fi
        read -p "$(echo -e ${B}Enter the number of the backup to restore:${E} )" num
        if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -ge "${#archives[@]}" ]; then
            echo -e "${R}Invalid selection.${E}"
            exit 1
        fi
        SELECTED_ARCHIVE="${archives[$num]}"
        echo -e "${B}Restoring from ${Y}$(basename "$SELECTED_ARCHIVE")${E}..."

        tar -xzf "$SELECTED_ARCHIVE" -C "$TEMP_DIR"

        echo -e "${B}→ Restoring ~/.config...${E}"
        rsync -a --delete "$TEMP_DIR/config/" "$CONFIG_SRC/"

        echo -e "${B}→ Restoring /boot/grub/themes...${E}"
        sudo rsync -a --delete "$TEMP_DIR/grub-themes/" "$GRUB_SRC/"

        echo -e "${B}→ Restoring /usr/share/sddm/themes...${E}"
        sudo rsync -a --delete "$TEMP_DIR/sddm-themes/" "$SDDM_SRC/"

        echo -e "${G}Restore complete.${E}"
        ;;
    [Cc])
        echo -e "${B}Creating new backup...${E}"

        echo -e "${B}→ Backing up ~/.config...${E}"
        rsync -a "$CONFIG_SRC/" "$TEMP_DIR/config/"

        echo -e "${B}→ Backing up /boot/grub/themes...${E}"
        sudo rsync -a "$GRUB_SRC/" "$TEMP_DIR/grub-themes/"

        echo -e "${B}→ Backing up /usr/share/sddm/themes...${E}"
        sudo rsync -a "$SDDM_SRC/" "$TEMP_DIR/sddm-themes/"

        echo -e "${B}→ Creating archive...${E}"
        tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$TEMP_DIR" .

        echo -e "${G}Backup saved as ${Y}$ARCHIVE_NAME${E}"
        ;;
    *)
        echo -e "${R}Invalid choice.${E}"
        exit 1
        ;;
esac

sudo rm -rf "$TEMP_DIR"
exit 0
