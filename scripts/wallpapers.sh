#!/usr/bin/env bash
# Wallpapers downloader for HyprArch (Yandex.Disk public folders)
# - choose base or full set
# - optional live wallpapers
# - recursive folder traversal (requires python3 for safe encoding)
# - visible wget progress & speed, no extra logging (clean terminal output)
set -euo pipefail

# -------------------------
# Colors
# -------------------------
R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"

# -------------------------
# Public links (updated)
# -------------------------
URL_BASE="https://disk.yandex.ru/d/3sXHmDf7g7Wtnw"  # base
URL_FULL="https://disk.yandex.ru/d/8l8qEGusJCH5Lg"  # full
URL_LIVE="https://disk.yandex.ru/d/AnS0b8PMUzetJQ"  # live

# -------------------------
# Paths
# -------------------------
WALLPAPER_DIR="$HOME/.config/hyprarch/wallpapers"

# -------------------------
# Helpers (colored output)
# -------------------------
info(){ printf "${B}%s${E}\n" "$1"; }
warn(){ printf "${Y}%s${E}\n" "$1"; }
err(){  printf "${R}%s${E}\n" "$1" >&2; }
succ(){ printf "${G}%s${E}\n" "$1"; }

info "
##############################
##  Wallpapers installation ##
##############################"

# -------------------------
# Ensure required command (optionally offer to install)
# -------------------------
ensure_cmd() {
  if ! command -v "$1" &>/dev/null; then
    warn "Command '$1' not found."
    printf "${Y}Install %s now via pacman? [y/N]: ${E}" "$1"
    read -r _yn
    if [[ "$_yn" =~ ^[Yy]$ ]]; then
      if ! command -v sudo &>/dev/null; then
        err "sudo not available — please install $1 manually and re-run."
        exit 1
      fi
      sudo pacman -Sy --noconfirm "$1" || { err "Failed to install $1"; exit 1; }
    else
      err "Required command $1 missing. Aborting."
      exit 1
    fi
  fi
}

# -------------------------
# Ensure tools
# -------------------------
ensure_cmd curl
ensure_cmd jq
ensure_cmd wget

# python3 optional but recommended for safe url-encoding & recursion
if command -v python3 &>/dev/null; then
  PYTHON_AVAIL=true
else
  PYTHON_AVAIL=false
  warn "python3 not found — recursion/encoding may be limited for complex paths."
fi

# -------------------------
# Prepare directories
# -------------------------
mkdir -p "$WALLPAPER_DIR" "$HOME/HyprArch"

# -------------------------
# Interactive choices
# -------------------------
printf "${B}Choose wallpaper set to download:${E}\n"
printf "  1) base (smaller set)\n"
printf "  2) full (entire set)\n"
printf "${B}Enter 1 or 2: ${E}"
read -r set_choice
case "$set_choice" in
  1) CHOOSE_SET="base"; SET_URL="$URL_BASE" ;;
  2) CHOOSE_SET="full"; SET_URL="$URL_FULL" ;;
  *) warn "Invalid choice — defaulting to 'base'."; CHOOSE_SET="base"; SET_URL="$URL_BASE" ;;
esac
info "Selected: $CHOOSE_SET"

printf "${B}Download live (animated) wallpapers as well? [y/N]: ${E}"
read -r live_choice
if [[ "$live_choice" =~ ^[Yy]$ ]]; then
  DOWNLOAD_LIVE=true
else
  DOWNLOAD_LIVE=false
fi

printf "${Y}If a file already exists — [s]kip (default) or [o]verwrite? (s/o): ${E}"
read -r overwrite_choice
if [[ "$overwrite_choice" =~ ^[Oo]$ ]]; then
  OVERWRITE=true
else
  OVERWRITE=false
fi

# -------------------------
# Arrays for summary
# -------------------------
DOWNLOAD_SUCC=()
DOWNLOAD_SKIP=()
DOWNLOAD_FAIL=()

# -------------------------
# urlencode helper (python preferred)
# -------------------------
urlencode() {
  if $PYTHON_AVAIL ; then
    python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$1"
  else
    # fallback: replace spaces only
    printf '%s' "${1// /%20}"
  fi
}

# -------------------------
# Trap for Ctrl+C
# -------------------------
_cleanup() {
  warn "Interrupted. Exiting."
  exit 130
}
trap _cleanup INT

# -------------------------
# Core: download_folder
# -------------------------
download_folder() {
  local public_key="$1"
  local dest_dir="$2"
  local relpath="${3:-}"

  mkdir -p "$dest_dir"

  local API_URL="https://cloud-api.yandex.net/v1/disk/public/resources"
  local query
  query="${API_URL}?public_key=$(urlencode "$public_key")"
  if [ -n "$relpath" ]; then
    query="${query}&path=$(urlencode "$relpath")"
  fi

  info "Listing: ${public_key}${relpath:+ -> $relpath}"
  local resp
  if ! resp=$(curl -sS "$query&limit=1000"); then
    warn "Failed to query Yandex.Disk for $public_key (path='$relpath')"
    return
  fi

  # If top-level object is a file (public link directly to a file)
  local top_type
  top_type=$(echo "$resp" | jq -r '.type // empty')
  if [ "$top_type" = "file" ]; then
    # get direct href via download API
    local href
    href=$(curl -sS "https://cloud-api.yandex.net/v1/disk/public/resources/download?public_key=$(urlencode "$public_key")" | jq -r '.href // empty')
    if [ -z "$href" ]; then
      href=$(echo "$resp" | jq -r '.file // empty')
    fi
    if [ -z "$href" ]; then
      warn "Cannot obtain download URL for public file. Skipping."
      return
    fi
    local name
    name=$(echo "$resp" | jq -r '.name // "downloaded.file"')
    local target="$dest_dir/$name"
    if [ -f "$target" ] && [ "$OVERWRITE" != true ]; then
      DOWNLOAD_SKIP+=("$target")
      printf "${Y}Skipping existing:${E} %s\n" "$target"
      return
    fi
    printf "${B}Downloading:${E} %s\n" "$name"
    # show progress & speed, hide verbose connection lines
    if wget --inet4-only --no-verbose --progress=bar:force:noscroll --tries=4 --timeout=30 --continue "$href" -O "$target"; then
      DOWNLOAD_SUCC+=("$target")
      printf "${G}Saved:${E} %s\n" "$target"
    else
      DOWNLOAD_FAIL+=("$target")
      err "Failed: $target"
      rm -f "$target" || true
    fi
    return
  fi

  # get items list
  local items
  items=$(echo "$resp" | jq -r '._embedded.items[] | @base64' 2>/dev/null || true)
  if [ -z "$items" ]; then
    warn "No items found at this path."
    # try fallback to download API for a possible single file
    local fallback_href
    fallback_href=$(curl -sS "https://cloud-api.yandex.net/v1/disk/public/resources/download?public_key=$(urlencode "$public_key")${relpath:+&path=$(urlencode "$relpath")}" | jq -r '.href // empty')
    if [ -n "$fallback_href" ]; then
      local fname
      fname=$(basename "$fallback_href")
      local target="$dest_dir/$fname"
      if [ -f "$target" ] && [ "$OVERWRITE" != true ]; then
        DOWNLOAD_SKIP+=("$target")
        printf "${Y}Skipping existing:${E} %s\n" "$target"
        return
      fi
      printf "${B}Downloading:${E} %s\n" "$fname"
      if wget --inet4-only --no-verbose --progress=bar:force:noscroll --tries=4 --timeout=30 --continue "$fallback_href" -O "$target"; then
        DOWNLOAD_SUCC+=("$target")
        printf "${G}Saved:${E} %s\n" "$target"
      else
        DOWNLOAD_FAIL+=("$target")
        err "Failed: $target"
        rm -f "$target" || true
      fi
    fi
    return
  fi

  local IFS=$'\n'
  for item_b64 in $items; do
    _jq() { echo "$item_b64" | base64 --decode | jq -r "$1"; }
    local name; name=$(_jq '.name')
    local type; type=$(_jq '.type')
    local file_url; file_url=$(_jq '.file')     # may be null
    local item_path; item_path=$(_jq '.path')   # use for download API fallback

    if [ "$type" = "dir" ]; then
      if $PYTHON_AVAIL; then
        info "Entering directory: $name"
        local new_rel
        if [ -n "$relpath" ]; then new_rel="${relpath%/}/$name"; else new_rel="$name"; fi
        download_folder "$public_key" "$dest_dir/$name" "$new_rel"
      else
        warn "Directory '$name' present but python3 missing — skipping recursion."
      fi
      continue
    fi

    # If .file missing, try download API for this item path
    if [ -z "$file_url" ] || [ "$file_url" = "null" ]; then
      local dl_href
      dl_href=$(curl -sS "https://cloud-api.yandex.net/v1/disk/public/resources/download?public_key=$(urlencode "$public_key")&path=$(urlencode "$item_path")" | jq -r '.href // empty')
      if [ -n "$dl_href" ]; then
        file_url="$dl_href"
      else
        warn "No direct file URL for '$name' and download API returned nothing — skipping."
        DOWNLOAD_FAIL+=("$dest_dir/$name")
        continue
      fi
    fi

    local target="$dest_dir/$name"
    if [ -f "$target" ] && [ "$OVERWRITE" != true ]; then
      DOWNLOAD_SKIP+=("$target")
      printf "${Y}Skipping existing:${E} %s\n" "$target"
      continue
    fi

    printf "${B}Downloading:${E} %s\n" "$name"
    if wget --inet4-only --no-verbose --progress=bar:force:noscroll --tries=4 --timeout=30 --continue "$file_url" -O "$target"; then
      DOWNLOAD_SUCC+=("$target")
      printf "${G}Saved:${E} %s\n" "$target"
    else
      DOWNLOAD_FAIL+=("$target")
      err "Failed: $target"
      rm -f "$target" || true
    fi
  done
}

# -------------------------
# Run downloads
# -------------------------
info "Starting downloads..."
if [ "$CHOOSE_SET" = "base" ]; then
  download_folder "$SET_URL" "$WALLPAPER_DIR/base"
else
  download_folder "$SET_URL" "$WALLPAPER_DIR/full"
fi

if [ "$DOWNLOAD_LIVE" = true ]; then
  download_folder "$URL_LIVE" "$WALLPAPER_DIR/live"
fi

# -------------------------
# Summary
# -------------------------
printf "\n"
succ "Download summary:"
printf "${G}Downloaded: %d${E}\n" "${#DOWNLOAD_SUCC[@]}"
for f in "${DOWNLOAD_SUCC[@]}"; do printf "  ${G}- %s${E}\n" "$f"; done

printf "${Y}Skipped (existing): %d${E}\n" "${#DOWNLOAD_SKIP[@]}"
for f in "${DOWNLOAD_SKIP[@]}"; do printf "  ${Y}- %s${E}\n" "$f"; done

if [ ${#DOWNLOAD_FAIL[@]} -gt 0 ]; then
  printf "${R}Failed downloads: %d${E}\n" "${#DOWNLOAD_FAIL[@]}"
  for f in "${DOWNLOAD_FAIL[@]}"; do printf "  ${R}- %s${E}\n" "$f"; done
  warn "Some files failed to download. Try re-running the script."
else
  succ "No failed downloads."
fi

printf "\n"
succ "Done."
exit 0
