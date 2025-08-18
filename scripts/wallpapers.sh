#!/usr/bin/env bash
set -euo pipefail

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"
#
info(){ printf "${B}%s\n" "$*"; }
ok(){   printf "${G}%s\n" "$*"; }
warn(){ printf "${Y}%s\n" "$*"; }
err(){  printf "${R}%s\n" "$*" >&2; }

URL_BASE="https://disk.yandex.ru/d/3sXHmDf7g7Wtnw"  # base
URL_FULL="https://disk.yandex.ru/d/8l8qEGusJCH5Lg"  # full
URL_LIVE="https://disk.yandex.ru/d/AnS0b8PMUzetJQ"  # live

WALLPAPER_DIR="$HOME/.config/hyprarch/wallpapers"

info "
##############################
##  Wallpapers installation ##
##############################"

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

ensure_cmd curl
ensure_cmd jq
ensure_cmd wget

if command -v python3 &>/dev/null; then
  PYTHON_AVAIL=true
else
  PYTHON_AVAIL=false
  warn "python3 not found — recursion/encoding may be limited for complex paths."
fi

mkdir -p "$WALLPAPER_DIR" "$HOME/HyprArch"


if [[ -z "$URL_BASE" || -z "$URL_FULL" ]]; then
  warn "Error: URL_BASE or URL_FULL not defined. Exiting."
  exit 1
fi

printf "${B}Choose wallpaper set to download:${E}\n"
printf "  0) skip wallpaper installation\n"
printf "  1) base (smaller set)\n"
printf "  2) full (entire set)\n"
printf "${B}Enter 0, 1, or 2: ${E}"
read -r set_choice
case "$set_choice" in
  0) info "Skipping wallpaper installation."; exit 0 ;;
  1) CHOOSE_SET="base"; SET_URL="$URL_BASE" ;;
  2) CHOOSE_SET="full"; SET_URL="$URL_FULL" ;;
  *) warn "Invalid choice — defaulting to 'base'."; CHOOSE_SET="base"; SET_URL="$URL_BASE" ;;
esac
info "Selected wallpaper set: $CHOOSE_SET"

printf "${B}Download live (animated) wallpapers? [y/N]: ${E}"
read -r live_choice
if [[ "$live_choice" =~ ^[Yy]$ ]]; then
  DOWNLOAD_LIVE=true
  info "Live wallpapers: enabled"
else
  DOWNLOAD_LIVE=false
  info "Live wallpapers: disabled"
fi

while true; do
  printf "${Y}If a file already exists — [s]kip (default) or [o]verwrite? (s/o): ${E}"
  read -r overwrite_choice
  case "$overwrite_choice" in
    [Ss]|"") OVERWRITE=false; break ;;
    [Oo]) OVERWRITE=true; break ;;
    *) warn "Invalid choice. Please enter 's' or 'o'." ;;
  esac
done
info "File handling: $( [[ $OVERWRITE == true ]] && echo "overwrite" || echo "skip" )"

printf "${B}Summary:${E}\n"
printf "  Wallpaper set: $CHOOSE_SET\n"
printf "  Live wallpapers: $( [[ $DOWNLOAD_LIVE == true ]] && echo "yes" || echo "no" )\n"
printf "  Existing files: $( [[ $OVERWRITE == true ]] && echo "overwrite" || echo "skip" )\n"

DOWNLOAD_SUCC=()
DOWNLOAD_SKIP=()
DOWNLOAD_FAIL=()

urlencode() {
  if $PYTHON_AVAIL ; then
    python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$1"
  else
    printf '%s' "${1// /%20}"
  fi
}

_cleanup() {
  warn "Interrupted. Exiting."
  exit 130
}
trap _cleanup INT

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

  local top_type
  top_type=$(echo "$resp" | jq -r '.type // empty')
  if [ "$top_type" = "file" ]; then
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

  local items
  items=$(echo "$resp" | jq -r '._embedded.items[] | @base64' 2>/dev/null || true)
  if [ -z "$items" ]; then
    warn "No items found at this path."
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
    local file_url; file_url=$(_jq '.file')
    local item_path; item_path=$(_jq '.path')

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

info "Starting downloads..."
if [ "$CHOOSE_SET" = "base" ]; then
  download_folder "$SET_URL" "$WALLPAPER_DIR/base"
else
  download_folder "$SET_URL" "$WALLPAPER_DIR/full"
fi

if [ "$DOWNLOAD_LIVE" = true ]; then
  download_folder "$URL_LIVE" "$WALLPAPER_DIR/live"
fi

printf "\n"
ok "Download summary:"
printf "${G}Downloaded: %d${E}\n" "${#DOWNLOAD_SUCC[@]}"
for f in "${DOWNLOAD_SUCC[@]}"; do printf "  ${G}- %s${E}\n" "$f"; done

printf "${Y}Skipped (existing): %d${E}\n" "${#DOWNLOAD_SKIP[@]}"
for f in "${DOWNLOAD_SKIP[@]}"; do printf "  ${Y}- %s${E}\n" "$f"; done

if [ ${#DOWNLOAD_FAIL[@]} -gt 0 ]; then
  printf "${R}Failed downloads: %d${E}\n" "${#DOWNLOAD_FAIL[@]}"
  for f in "${DOWNLOAD_FAIL[@]}"; do printf "  ${R}- %s${E}\n" "$f"; done
  warn "Some files failed to download. Try re-running the script."
else
  ok "No failed downloads."
fi

printf "\n"
ok "Done."
exit 0
