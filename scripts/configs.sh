#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# sync_configs.sh — COPY ~/HyprArch/config(s) -> ~/.config safely, with verification
R="\e[31m"; G="\e[32m"; B="\e[34m"; Y="\e[33m"; E="\e[0m"
info(){ printf "${B}%s${E}\n" "$*"; }
ok(){   printf "${G}%s${E}\n" "$*"; }
warn(){ printf "${Y}%s${E}\n" "$*"; }
err(){  printf "${R}%s${E}\n" "$*" >&2; }

usage(){
  cat <<EOF
Usage: $0 [-y|--yes]

Copies configuration files from ~/HyprArch/config or ~/HyprArch/configs into ~/.config

Options:
  -y, --yes   do not ask for confirmation before removing existing matching items
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

# determine target user/home (works with sudo)
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="$(id -un)"
fi
TARGET_HOME="$(eval echo "~$TARGET_USER")"

SRC_DIR=""
if [ -d "$TARGET_HOME/HyprArch/config" ]; then
  SRC_DIR="$TARGET_HOME/HyprArch/config"
elif [ -d "$TARGET_HOME/HyprArch/configs" ]; then
  SRC_DIR="$TARGET_HOME/HyprArch/configs"
else
  err "Source directory not found. Expected either:"
  err "  $TARGET_HOME/HyprArch/config  or  $TARGET_HOME/HyprArch/configs"
  exit 1
fi

DEST_DIR="$TARGET_HOME/.config"

info "Source: $SRC_DIR"
info "Destination: $DEST_DIR"
info "Target user: $TARGET_USER"

confirm(){
  local prompt="$1"
  if $AUTO_YES; then
    return 0
  fi
  read -rp "$(printf "${Y}%s (y, N): ${E}" "$prompt")" _ans
  [[ "$_ans" =~ ^[Yy]$ ]]
}

# gather items to copy
shopt -s dotglob nullglob
items=()
for p in "$SRC_DIR"/*; do
  [ -e "$p" ] || continue
  items+=("$p")
done
shopt -u dotglob nullglob

if [ ${#items[@]} -eq 0 ]; then
  warn "No files or directories to copy in $SRC_DIR"
  exit 0
fi

# Partition hypr items to process them last
hypr_items=()
normal_items=()
for p in "${items[@]}"; do
  name="$(basename "$p")"
  lname="${name,,}"
  if [[ "$lname" == "hypr" || "$lname" == "hyprland" ]]; then
    hypr_items+=("$p")
  else
    normal_items+=("$p")
  fi
done

# Ensure destination directory exists and has correct ownership
if [ ! -d "$DEST_DIR" ]; then
  if [ "$TARGET_USER" != "$(id -un)" ]; then
    sudo -u "$TARGET_USER" mkdir -p "$DEST_DIR"
  else
    mkdir -p "$DEST_DIR"
  fi
  chown "$TARGET_USER":"$TARGET_USER" "$DEST_DIR" || true
fi

# Remove existing dest entry if exists
remove_if_exists(){
  local name="$1"
  local dst="$DEST_DIR/$name"
  if [ -e "$dst" ]; then
    info "Removing existing $dst"
    if rm -rf -- "$dst"; then
      ok "Removed $dst"
      return 0
    else
      err "Failed to remove $dst"
      return 1
    fi
  fi
  return 0
}

copied_ok=()
copied_fail=()

# Helper to copy list of items
copy_list(){
  local -n arr=$1
  for src in "${arr[@]}"; do
    name="$(basename "$src")"
    # confirm removal of existing dest
    if ! confirm "Will remove existing $DEST_DIR/$name if present and then copy. Continue?"; then
      warn "User cancelled removal for $name — skipping this item."
      copied_fail+=("$name (skipped-by-user)")
      continue
    fi
    if ! remove_if_exists "$name"; then
      copied_fail+=("$name (remove-failed)")
      continue
    fi
    info "Copying $name -> $DEST_DIR/"
    # copy (preserve attributes) WITHOUT removing source
    if cp -a -- "$src" "$DEST_DIR/"; then
      # ensure ownership belongs to target user
      chown -R "$TARGET_USER":"$TARGET_USER" "$DEST_DIR/$name" || true
      ok "Copied: $name"
      copied_ok+=("$name")
    else
      err "Failed to copy $name"
      copied_fail+=("$name (cp-failed)")
    fi
    sync
    sleep 0.2
  done
}

# Copy normal items first
if [ ${#normal_items[@]} -gt 0 ]; then
  info "Copying normal items..."
  copy_list normal_items
fi

# Then hypr items last
if [ ${#hypr_items[@]} -gt 0 ]; then
  info "Copying Hypr-related items last to minimize display glitches..."
  copy_list hypr_items

  # Try to reload hypr if available
  if command -v hyprctl >/dev/null 2>&1; then
    info "Attempting to reload Hyprland config: hyprctl reload"
    if hyprctl reload; then
      ok "hyprctl reload succeeded."
    else
      warn "hyprctl reload failed — changes will apply after relogin/reboot."
    fi
  else
    warn "hyprctl not found — cannot auto-reload Hyprland."
  fi
fi

# Verification step
info "Verifying copied items..."
verify_ok=()
verify_fail=()
for n in "${copied_ok[@]}"; do
  if [ -e "$DEST_DIR/$n" ] && [ -e "$SRC_DIR/$n" ]; then
    verify_ok+=("$n")
  else
    verify_fail+=("$n")
  fi
done

echo
info "Summary:"
ok "Successfully copied (${#verify_ok[@]}):"
if [ ${#verify_ok[@]} -gt 0 ]; then
  for v in "${verify_ok[@]}"; do
    printf "  - %s\n" "$v"
  done
else
  echo "  (none)"
fi

if [ ${#copied_fail[@]} -gt 0 ] || [ ${#verify_fail[@]} -gt 0 ]; then
  err "Failed or incomplete (${#copied_fail[@]} failed copies, ${#verify_fail[@]} failed verifies):"
  for v in "${copied_fail[@]}"; do
    printf "  - %s\n" "$v"
  done
  for v in "${verify_fail[@]}"; do
    printf "  - %s (verify-failed)\n" "$v"
  done
  exit 2
else
  ok "All copied items verified present in $DEST_DIR and original files remain in $SRC_DIR."
fi

exit 0
