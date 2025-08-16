#!/usr/bin/env bash
set -euo pipefail

# Colors
BLUE="\e[34m"
YELLOW="\e[1;33m"
GREEN="\e[0;32m"
RED="\e[0;31m"
END="\e[0m"

info()  { echo -e "${BLUE}$*${END}"; }
warn()  { echo -e "${YELLOW}$*${END}"; }
ok()    { echo -e "${GREEN}$*${END}"; }
err()   { echo -e "${RED}$*${END}" >&2; }

if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="$(id -un)"
fi
TARGET_HOME="$(eval echo "~$TARGET_USER")"

CONFIG_DIR="$TARGET_HOME/.config/Code/User"
SRC_DIR="$TARGET_HOME/HyprArch/customs/vs-code/Code/User"
EXT_FILE="$TARGET_HOME/HyprArch/customs/vs-code/vscode-extensions.txt"

if [ "$TARGET_USER" != "$(id -un)" ]; then
  SUDO_AS_USER=(sudo -u "$TARGET_USER")
else
  SUDO_AS_USER=()
fi

info "HyprVSCode custom setup"
echo

read -rp "$(echo -e "${BLUE}Install custom HyprVSCode for user ${TARGET_USER}? (y/N): ${END}")" install_vscode
if [[ ! "$install_vscode" =~ ^[Yy]$ ]]; then
  warn "Skipping HyprVSCode customization."
  exit 0
fi

info "Preparing VS Code config directory: ${CONFIG_DIR}"
mkdir -p "$CONFIG_DIR"
chown "$TARGET_USER":"$TARGET_USER" "$CONFIG_DIR"

for file in keybindings.json settings.json; do
  src="$SRC_DIR/$file"
  dst="$CONFIG_DIR/$file"

  if [ -f "$dst" ]; then
    bak="${dst}.bak.$(date +%s)"
    cp -a "$dst" "$bak"
    chown "$TARGET_USER":"$TARGET_USER" "$bak"
    info "Backed up existing $file -> $(basename "$bak")"
  fi

  if [ -f "$src" ]; then
    cp -a "$src" "$dst"
    chown "$TARGET_USER":"$TARGET_USER" "$dst"
    ok "Copied $file to $dst"
  else
    warn "File $src not found: skipping $file"
  fi
done

if ! "${SUDO_AS_USER[@]}" sh -c 'command -v code >/dev/null 2>&1' ; then
  err "VS Code CLI 'code' not found in ${TARGET_USER}'s PATH."
  err "Make sure Visual Studio Code is installed and the 'code' command is available."
  exit 1
fi

have_network() {
  ping -c1 -W2 1.1.1.1 >/dev/null 2>&1
}

if [ ! -f "$EXT_FILE" ]; then
  err "Extensions list not found: $EXT_FILE"
  exit 1
fi

info "Installing extensions from: $EXT_FILE"
installed_count=0
skipped_count=0
failed_count=0

is_installed() {
  local ext="$1"
  "${SUDO_AS_USER[@]}" sh -c "code --list-extensions" | grep -Fxq "$ext"
}

install_extension() {
  local ext="$1"

  if [[ -z "$ext" || "$ext" != *.*/* && "$ext" != *.* ]]; then
    warn "Skipping invalid extension name: '$ext'"
    skipped_count=$((skipped_count+1))
    return 0
  fi

  if is_installed "$ext"; then
    ok "Already installed: $ext"
    skipped_count=$((skipped_count+1))
    return 0
  fi

  if ! have_network; then
    warn "No network detected — skipping install of: $ext"
    failed_count=$((failed_count+1))
    return 1
  fi

  info "→ Installing: $ext"
  if "${SUDO_AS_USER[@]}" sh -c "code --install-extension '$ext' >/dev/null 2>&1"; then
    ok "Installed: $ext"
    installed_count=$((installed_count+1))
    return 0
  else
    err "Failed to install: $ext"
    failed_count=$((failed_count+1))
    return 1
  fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
  install_extension "$line"
done < "$EXT_FILE"

echo
ok "Extensions installation summary: installed=${installed_count}, skipped=${skipped_count}, failed=${failed_count}"

if [ "$failed_count" -ne 0 ]; then
  warn "Some extensions failed to install. You can re-run this script later to try again."
else
  ok "All requested extensions are present (installed or already existed)."
fi

ok "HyprVSCode customization finished for user ${TARGET_USER}."
exit 0
