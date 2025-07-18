#!/bin/bash
set -e
# Ensure rsync is installed (for Arch-based systems)
if ! command -v rsync &>/dev/null; then
    echo "'rsync' is not installed. Installing via pacman..."
    if ! command -v sudo &>/dev/null; then
        echo "'sudo' is not available. Please install rsync manually."
        exit 1
    fi
    echo "Updating pacman database..."
    sudo pacman -Sy --noconfirm
    echo "⬇ Installing rsync..."
    sudo pacman -S --noconfirm rsync || {
        echo "Failed to install rsync. Exiting."
        exit 1
    }
    echo "✅ rsync installed."
fi

BACKUP_DIR="$HOME/.config/hyprarch/backups"
TEMP_DIR="$(mktemp -d)"
TIMESTAMP="$(date +"%d-%m_%H-%M")"
ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"

CONFIG_SRC="$HOME/.config"
GRUB_SRC="/boot/grub/themes"
SDDM_SRC="/usr/share/sddm/themes"

mkdir -p "$BACKUP_DIR"
echo "Available backups:"
mapfile -t archives < <(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | sort -r)

if [ ${#archives[@]} -eq 0 ]; then
    echo "— No backups found."
else
    for i in "${!archives[@]}"; do
        fname=$(basename "${archives[$i]}")
        echo "$i) $fname"
    done
fi

echo
read -p "Do you want to [s]skip [r]estore or [c]reate a new backup? (s/r/c): " choice

case "$choice" in
    [Ss])
        echo "Skipping backup."
        ;;
    [Rr])
        if [ ${#archives[@]} -eq 0 ]; then
            echo "No backups available to restore."
            exit 1
        fi
        read -p "Enter the number of the backup to restore: " num
        SELECTED_ARCHIVE="${archives[$num]}"
        echo "Restoring from $(basename "$SELECTED_ARCHIVE")..."

        tar -xzf "$SELECTED_ARCHIVE" -C "$TEMP_DIR"

        echo "→ Restoring ~/.config..."
        rsync -a --delete "$TEMP_DIR/config/" "$CONFIG_SRC/"

        echo "→ Restoring /boot/grub/themes..."
        sudo rsync -a --delete "$TEMP_DIR/grub-themes/" "$GRUB_SRC/"

        echo "→ Restoring /usr/share/sddm/themes..."
        sudo rsync -a --delete "$TEMP_DIR/sddm-themes/" "$SDDM_SRC/"

        echo "Restore complete."
        ;;
    [Cc])
        echo "Creating new backup..."

        echo "→ Backing up ~/.config..."
        rsync -a "$CONFIG_SRC/" "$TEMP_DIR/config/"

        echo "→ Backing up /boot/grub/themes..."
        sudo rsync -a "$GRUB_SRC/" "$TEMP_DIR/grub-themes/"

        echo "→ Backing up /usr/share/sddm/themes..."
        sudo rsync -a "$SDDM_SRC/" "$TEMP_DIR/sddm-themes/"

        echo "→ Creating archive..."
        tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$TEMP_DIR" .

        echo "Backup saved as $ARCHIVE_NAME"
        ;;
    *)
        echo "Invalid choice."
        exit 1
        ;;
esac

# Cleanup
sudo rm -rf "$TEMP_DIR"
