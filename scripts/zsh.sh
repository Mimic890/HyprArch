#!/usr/bin/env bash
set -euo pipefail

# Colors
B="\e[34m"
G="\e[32m"
R="\e[31m"
Y="\e[33m"
E="\e[0m"

info()  { echo -e "${B}$*${E}"; }
ok()    { echo -e "${G}$*${E}"; }
warn()  { echo -e "${Y}$*${E}"; }
err()   { echo -e "${R}$*${E}" >&2; }

# Determine target user and home (support running with sudo)
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="$(eval echo "~$SUDO_USER")"
else
    TARGET_USER="${USER:-$(id -un)}"
    TARGET_HOME="${HOME:-$(eval echo "~$TARGET_USER")}"
fi

ZSH_PATH="$(command -v zsh || true)"
ZSH_PATH="${ZSH_PATH:-/usr/bin/zsh}"

CUSTOMS_DIR="$TARGET_HOME/HyprArch/customs/zsh"
ZINIT_DIR="$TARGET_HOME/.local/share/zinit/zinit.git"
STARSHIP_CONF_SRC="$CUSTOMS_DIR/starship.toml"
ZSHRC_SRC="$CUSTOMS_DIR/.zshrc"
ZSHRC_DST="$TARGET_HOME/.zshrc"
STARSHIP_DST_DIR="$TARGET_HOME/.config"
STARSHIP_DST_FILE="$STARSHIP_DST_DIR/starship.toml"

if ! command -v pacman &>/dev/null; then
    err "pacman not found. This script expects Arch/pacman."
    exit 1
fi

if ! command -v zsh &>/dev/null; then
    info "Installing zsh..."
    sudo pacman -S --noconfirm zsh
    ok "zsh installed."
else
    ok "zsh is already installed."
fi

ZSH_PATH="$(command -v zsh)"
if ! grep -qxF "$ZSH_PATH" /etc/shells; then
    info "Adding $ZSH_PATH to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    ok "Added $ZSH_PATH to /etc/shells."
fi

CURRENT_SHELL="$(getent passwd "$TARGET_USER" | cut -d: -f7 || true)"
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    info "Setting zsh as the default shell for user $TARGET_USER..."
    if [ "$TARGET_USER" != "$(id -un)" ]; then
        sudo chsh -s "$ZSH_PATH" "$TARGET_USER"
    else
        chsh -s "$ZSH_PATH"
    fi
    ok "Default shell changed to $ZSH_PATH for $TARGET_USER."
else
    ok "zsh is already the default shell for $TARGET_USER."
fi

if ! command -v git &>/dev/null; then
    info "Installing git (required to install zinit)..."
    sudo pacman -S --noconfirm git
    ok "git installed."
fi

info "Installing zinit..."
install -d -m 0755 "$(dirname "$ZINIT_DIR")"
if [ -d "$ZINIT_DIR" ]; then
    warn "Existing zinit directory found — removing it to reinstall."
    rm -rf "$ZINIT_DIR"
fi

if [ "$TARGET_USER" != "$(id -un)" ]; then
    sudo -u "$TARGET_USER" git clone https://github.com/zdharma-continuum/zinit "$ZINIT_DIR"
else
    git clone https://github.com/zdharma-continuum/zinit "$ZINIT_DIR"
fi
ok "zinit installed to $ZINIT_DIR."

if ! command -v starship &>/dev/null; then
    info "Installing starship..."
    sudo pacman -S --noconfirm starship
    ok "starship installed."
else
    ok "starship is already installed."
fi

info "Copying starship configuration..."
mkdir -p "$STARSHIP_DST_DIR"
if [ -f "$STARSHIP_CONF_SRC" ]; then
    cp -f "$STARSHIP_CONF_SRC" "$STARSHIP_DST_FILE"
    chown "$TARGET_USER":"$TARGET_USER" "$STARSHIP_DST_FILE"
    ok "Copied starship config to $STARSHIP_DST_FILE."
else
    warn "starship.toml not found in $CUSTOMS_DIR — skipping starship config copy."
fi

info "Installing .zshrc..."
if [ -f "$ZSHRC_SRC" ]; then
    if [ -f "$ZSHRC_DST" ]; then
        cp -f "$ZSHRC_DST" "${ZSHRC_DST}.bak.$(date +%s)"
        warn "Backed up existing .zshrc to ${ZSHRC_DST}.bak.<timestamp>."
    fi
    cp -f "$ZSHRC_SRC" "$ZSHRC_DST"
    chown "$TARGET_USER":"$TARGET_USER" "$ZSHRC_DST"
    ok ".zshrc installed to $ZSHRC_DST."
else
    warn ".zshrc not found in $CUSTOMS_DIR — skipping .zshrc install."
fi

ok "Zsh installation and configuration completed successfully."
exit 0
