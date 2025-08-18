#!/bin/bash
set -e

B="\e[34m"
G="\e[32m"
Y="\e[33m"
R="\e[31m"
E="\e[0m"

info(){  echo -e "${B}$*"; }
ok(){    echo -e "${G}$*"; }
warn(){  echo -e "${Y}$*"; }
err(){   echo -e "${R}$*" >&2; }

if ! command -v rsync &>/dev/null; then
    warn "'rsync' is not installed. Installing via pacman..."
    if ! command -v sudo &>/dev/null; then
        err "'sudo' is not available. Please install rsync manually."
        exit 1
    fi
    info "Updating pacman database..."
    sudo pacman -Sy --noconfirm
    info "Installing rsync..."
    sudo pacman -S --noconfirm rsync || {
        err "Failed to install rsync. Exiting."
        exit 1
    }
    ok "rsync installed successfully."
fi

BACKUP_DIR="$HOME/.config/hyprarch/backups"
TEMP_DIR="$(mktemp -d)"
TIMESTAMP="$(date +"%d-%m_%H-%M")"
ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"

CONFIG_SRC="$HOME/.config"
GRUB_SRC="/boot/grub/themes"
SDDM_SRC="/usr/share/sddm/themes"

mkdir -p "$BACKUP_DIR"
info "Available backups:"
mapfile -t archives < <(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | sort -r)

if [ ${#archives[@]} -eq 0 ]; then
    warn "— No backups found."
else
    for i in "${!archives[@]}"; do
        fname=$(basename "${archives[$i]}")
        warn "$i)${E} $fname"
    done
fi

echo
read -p $'\e[34mDo you want to [s]kip, [r]estore or [c]reate a new backup? (s/r/c): \e[0m' choice

case "$choice" in
    [Ss])
        warn "Skipping backup."
        ;;
    [Rr])
        if [ ${#archives[@]} -eq 0 ]; then
            err "No backups available to restore."
            exit 1
        fi
        read -p "$(echo -e ${B}Enter the number of the backup to restore:${E} )" num
        if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -ge "${#archives[@]}" ]; then
            err "Invalid selection."
            exit 1
        fi
        SELECTED_ARCHIVE="${archives[$num]}"
        info "Restoring from ${Y}$(basename "$SELECTED_ARCHIVE")${E}..."
        tar -xzf "$SELECTED_ARCHIVE" -C "$TEMP_DIR"
        info "Restoring ~/.config..."
        rsync -a --delete "$TEMP_DIR/config/" "$CONFIG_SRC/"
        info "Restoring /boot/grub/themes..."
        sudo rsync -a --delete "$TEMP_DIR/grub-themes/" "$GRUB_SRC/"
        info "Restoring /usr/share/sddm/themes..."
        sudo rsync -a --delete "$TEMP_DIR/sddm-themes/" "$SDDM_SRC/"
        ok "Restore complete."
        ;;
    [Cc])
        info "Creating new backup..."
        info "Backing up ~/.config..."
        rsync -a "$CONFIG_SRC/" "$TEMP_DIR/config/"
        info "Backing up /boot/grub/themes..."
        sudo rsync -a "$GRUB_SRC/" "$TEMP_DIR/grub-themes/"
        info "Backing up /usr/share/sddm/themes..."
        sudo rsync -a "$SDDM_SRC/" "$TEMP_DIR/sddm-themes/"
        info "Creating archive..."
        tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$TEMP_DIR" .
        ok "Backup saved as ${Y}$ARCHIVE_NAME"
        ;;
    *)
        err "Invalid choice."
        exit 1
        ;;
esac

sudo rm -rf "$TEMP_DIR"
exit 0
