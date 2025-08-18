#!/usr/bin/env bash
# hyprarch_replace_os_release.sh
# Self-contained, safe replacement of /etc/os-release with a custom HyprArch os-release.
# - backups existing /etc/os-release
# - validates minimal fields
# - uses atomic install with correct permissions
# - interactive, but accepts -y for automatic yes
# This script is meant to be called directly from the main installer.

set -euo pipefail
IFS=$'\n\t'

# Colors
B="\e[34m"
G="\e[32m"
Y="\e[33m"
R="\e[31m"
E="\e[0m"

info(){  echo -e "${B}$*${E}"; }
ok(){    echo -e "${G}$*${E}"; }
warn(){  echo -e "${Y}$*${E}"; }
err(){   echo -e "${R}$*${E}" >&2; }

# Usage
usage(){
    cat <<EOF
Usage: $0 [-y|--yes]

This script replaces /etc/os-release with a custom os-release file.
If you have a file at: 
  \$HOME/HyprArch/customs/os-release  (for the original user when run under sudo)
it will be used. If not present, a default HyprArch os-release will be created
and offered for preview before writing.

Run as root (sudo):
  sudo bash $0

Options:
  -y, --yes   non-interactive: answer yes to all confirmations
EOF
}

AUTO_YES=false
while [[ ${1:-} != "" ]]; do
    case "$1" in
        -y|--yes) AUTO_YES=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) err "Unknown arg: $1"; usage; exit 2 ;;
    esac
done

# Must run as root
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root. Use sudo." 
    exit 2
fi

# Find original non-root user (if script launched via sudo)
ORIG_USER="${SUDO_USER:-$(logname 2>/dev/null || true)}"
if [[ -z "$ORIG_USER" || "$ORIG_USER" == "root" ]]; then
    ORIG_USER=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1; exit}' /etc/passwd || true)
    ORIG_USER=${ORIG_USER:-root}
fi
ORIG_HOME="$(eval echo "~$ORIG_USER")"

CUSTOM_OS_RELEASE="$ORIG_HOME/HyprArch/customs/os-release"
TARGET="/etc/os-release"

TMPFILE=""
cleanup(){
    if [[ -n "$TMPFILE" && -f "$TMPFILE" ]]; then
        rm -f "$TMPFILE" || true
    fi
}
trap cleanup EXIT

confirm(){
    if $AUTO_YES; then
        return 0
    fi
    local prompt="$1"
    local default=${2:-N}
    read -rp "$(echo -e "${Y}${prompt} (y, N): ${E}")" _ans
    [[ "$_ans" =~ ^[Yy]$ ]]
}

make_default_os_release(){
    cat <<'EOF'
# HyprArch default /etc/os-release template
NAME="HyprArch"
PRETTY_NAME="HyprArch (custom)"
ID=hyprarch
VERSION="rolling"
VERSION_ID="rolling"
BUILD_ID="hyprarch"
HOME_URL="https://hyprarch.ru"
SUPPORT_URL="https://hyprarch.ru/contact"
BUG_REPORT_URL="https://hyprarch.ru/bugs"
ANSI_COLOR="5c76cc"
EOF
}

info "HyprArch os-release replacer\n"
info "Detected original user: ${ORIG_USER} (home: ${ORIG_HOME})"

# Decide source
if [[ -f "$CUSTOM_OS_RELEASE" ]]; then
    info "Found custom os-release at: $CUSTOM_OS_RELEASE"
    if confirm "Preview the custom os-release file?" N; then
        echo
        info "--- start preview ($CUSTOM_OS_RELEASE) ---"
        sed -n '1,500p' "$CUSTOM_OS_RELEASE" || true
        info "---- end preview ----"
        echo
    fi
    if ! confirm "Use this file to replace $TARGET?" N; then
        warn "User chose not to use the custom file. Aborting."; exit 0
    fi
    TMPFILE=$(mktemp -p /tmp hypr-os-release.XXXXXX)
    cp -- "$CUSTOM_OS_RELEASE" "$TMPFILE"
else
    warn "No custom os-release found at: $CUSTOM_OS_RELEASE"
    if confirm "Create a default HyprArch os-release and use it?" Y; then
        TMPFILE=$(mktemp -p /tmp hypr-os-release.XXXXXX)
        make_default_os_release >"$TMPFILE"
        info "Preview of the generated os-release:"
        sed -n '1,500p' "$TMPFILE" || true
        if ! confirm "Proceed to install this generated file to $TARGET?" Y; then
            warn "User cancelled. Aborting."; exit 0
        fi
    else
        warn "User chose not to create default. Aborting."; exit 0
    fi
fi

# Basic validation: must contain NAME and ID
if ! grep -Eq '^NAME=' "$TMPFILE"; then
    err "Validation failed: file does not contain a NAME= line."; exit 3
fi
if ! grep -Eq '^ID=' "$TMPFILE"; then
    err "Validation failed: file does not contain an ID= line."; exit 3
fi

# Backup existing target if present
if [[ -f "$TARGET" ]]; then
    TS="$(date +%Y%m%d-%H%M%S)"
    BACKUP="${TARGET}.hyprarch.bak-${TS}"
    info "Backing up existing $TARGET -> $BACKUP"
    cp --preserve=mode,ownership,timestamps "$TARGET" "$BACKUP"
fi

# Install atomically: write to temp in same FS then move via install
FINAL_TMP="$(mktemp -p /tmp hypr-os-release.final.XXXXXX)"
cat "$TMPFILE" >"$FINAL_TMP"
chmod 0644 "$FINAL_TMP"
chown root:root "$FINAL_TMP"

info "Installing $TARGET (atomic)"
install -m 0644 -o root -g root "$FINAL_TMP" "$TARGET"
RET=$?
if [[ $RET -ne 0 ]]; then
    err "Failed to install $TARGET (exit $RET)"
    exit $RET
fi

ok "Replacement complete. New $TARGET installed."

if [[ -f "$BACKUP" ]]; then
    if command -v diff >/dev/null 2>&1; then
        info "Showing a brief diff (old -> new):"
        diff -u --label "$BACKUP" --label "$TARGET" "$BACKUP" "$TARGET" || true
    fi
fi

ok "Done. If you need to restore the backup, run:\n  sudo cp -- \"$BACKUP\" \"$TARGET\" && sudo chown root:root \"$TARGET\""

exit 0
