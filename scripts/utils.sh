#!/usr/bin/env bash
set -euo pipefail

# Scalable installer for CLI multimedia & network utilities on Arch Linux.
# - multi-select categories -> choose packages per category (Enter = all)
# - split repo vs AUR packages; install repo via pacman, AUR via paru or yay
# - menus/prompts printed to stderr; chosen package names to stdout

RESET='\e[0m'; BOLD='\e[1m'
RED='\e[0;31m'; GREEN='\e[0;32m'; YELLOW='\e[0;33m'
BLUE='\e[0;34m'; MAGENTA='\e[0;35m'; CYAN='\e[0;36m'; WHITE='\e[0;37m'

log(){ printf "${WHITE}%b${RESET}\n" "$*"; }
info(){ printf "${BLUE}%b${RESET}\n" "$*"; }
ok(){ printf "${GREEN}%b${RESET}\n" "$*"; }
warn(){ printf "${YELLOW}%b${RESET}\n" "$*"; }
err(){ printf "${RED}%b${RESET}\n" "$*" >&2; }
prompt(){ printf "${BOLD}${MAGENTA}%b${RESET}" "$*"; }
header(){ printf "\n${BOLD}${CYAN}##################################################\n# %b\n##################################################${RESET}\n" "$@"; }

# categories
declare -a categories=("video" "audio" "photo" "network")
declare -A category_name category_desc

category_name["video"]="Video"
category_desc["video"]="CLI utilities for video conversion, muxing and analysis."

category_name["audio"]="Audio"
category_desc["audio"]="Audio encoding, ripping and processing tools."

category_name["photo"]="Photo & Images"
category_desc["photo"]="Image conversion, metadata and optimization utilities."

category_name["network"]="Network"
category_desc["network"]="Network scanning, capture and troubleshooting tools."

# packages arrays: "pkg:::desc"
category_video_packages=(
  "ffmpeg:::Audio/video conversion & processing"
  "yt-dlp:::Download videos from many websites"
  "mkvtoolnix-cli:::Matroska (MKV) tools"
  "mediainfo:::Show technical media info"
  "ffmpegthumbnailer:::Generate video thumbnails"
  "mpv:::Lightweight media player"
)

category_audio_packages=(
  "sox:::Sound processing (effects, conversions)"
  "lame:::MP3 encoder"
  "flac:::Free Lossless Audio Codec tools"
  # abcde/shntool are AUR-only; using cdparanoia as repo alternative
  "cdparanoia:::CD extraction tool"
  "beets:::Music library manager"
)

category_photo_packages=(
  "imagemagick:::Image creation, editing and conversion"
  "graphicsmagick:::Lighter alternative to ImageMagick"
  "exiftool:::Read/write EXIF, IPTC, XMP metadata"
  "pngquant:::Lossy PNG compression"
  "jpegoptim:::Optimize JPEG files"
  "libraw:::Raw image decoding library"
)

# explicit provider for netcat to avoid pacman prompt
category_network_packages=(
  "nmap:::Network scanner and port discovery"
  "tcpdump:::Packet capture and filtering"
  "wireshark-cli:::CLI packet analysis (tshark)"
  "mtr:::Network diagnostics (traceroute + ping)"
  "traceroute:::Show packet route to host"
  "openbsd-netcat:::OpenBSD netcat (explicit provider)"
  "iperf3:::Network throughput testing"
  "curl:::Data transfer from/to a server"
  "wget:::Non-interactive downloader"
)

# helpers
die(){ err "$*"; exit 1; }

parse_number_list(){
  local input="$*"; input="${input//,/ }"
  read -ra tokens <<< "$input"
  local out=()
  for t in "${tokens[@]}"; do [[ "$t" =~ ^[0-9]+$ ]] && out+=("$t"); done
  printf "%s\n" "${out[@]}"
}

select_categories(){
  header "Select categories (multiple allowed, space or comma separated)" >&2
  for i in "${!categories[@]}"; do
    key="${categories[$i]}"
    printf "%s) %s - %s\n" "$((i+1))" "${category_name[$key]}" "${category_desc[$key]}" >&2
  done
  warn "q) Quit" >&2; echo >&2
  read -rp "$(prompt "Enter category numbers (e.g., 1 3) or Enter for all: ")" raw
  [[ "${raw,,}" == "q" ]] && exit 0
  if [[ -z "$raw" ]]; then selected_category_keys=("${categories[@]}"); return; fi
  mapfile -t selected_indices < <(parse_number_list "$raw")
  if [ "${#selected_indices[@]}" -eq 0 ]; then err "Invalid input."; select_categories; return; fi
  selected_category_keys=()
  for idx in "${selected_indices[@]}"; do
    if [[ $idx -lt 1 || $idx -gt ${#categories[@]} ]]; then err "Index $idx out of range"; select_categories; return; fi
    selected_category_keys+=("${categories[$((idx-1))]}")
  done
}

select_packages_for_category(){
  local key="$1"
  local arr_name="category_${key}_packages[@]"
  local -a packages=("${!arr_name}")

  header "Category: ${category_name[$key]} — ${category_desc[$key]}" >&2
  warn "b) Back to category selection" >&2
  info "Number | Package - Description" >&2
  for i in "${!packages[@]}"; do
    IFS=":::" read -r pkg desc <<< "${packages[$i]}"
    printf "%2d) %s - %s\n" "$((i+1))" "$pkg" "$desc" >&2
  done
  echo >&2
  printf "%s" "$(prompt "Enter package numbers (e.g., 1 3) or Enter to select all: ")" >&2
  read -r raw
  [[ "${raw,,}" == "b" ]] && return 2

  local chosen=()
  if [[ -z "$raw" ]]; then
    for p in "${packages[@]}"; do IFS=":::" read -r pkg desc <<< "$p"; chosen+=("$pkg"); done
  else
    mapfile -t nums < <(parse_number_list "$raw")
    for n in "${nums[@]}"; do
      if [ "$n" -ge 1 ] && [ "$n" -le "${#packages[@]}" ]; then
        IFS=":::" read -r pkg desc <<< "${packages[$((n-1))]}"
        chosen+=("$pkg")
      fi
    done
  fi

  printf "%s\n" "${chosen[@]}"
  return 0
}

# find available AUR helper (priority: paru -> yay)
find_aur_helper(){
  if command -v paru >/dev/null 2>&1; then
    echo "paru"
  elif command -v yay >/dev/null 2>&1; then
    echo "yay"
  else
    echo ""
  fi
}

# split selected packages into repo and aur lists
split_repo_and_aur(){
  repo_packages=(); aur_packages=()
  for pkg in "${selected_packages[@]}"; do
    # pacman -Si returns 0 if package exists in repos
    if pacman -Si "$pkg" > /dev/null 2>&1; then
      repo_packages+=("$pkg")
    else
      aur_packages+=("$pkg")
    fi
  done
}

install_repo_packages(){
  if [ "${#repo_packages[@]}" -eq 0 ]; then
    ok "No repository packages to install."
    return
  fi
  ok "Installing repository packages via pacman..."
  sudo pacman -Syu --needed --noconfirm "${repo_packages[@]}"
}

install_aur_packages(){
  if [ "${#aur_packages[@]}" -eq 0 ]; then
    ok "No AUR packages to install."
    return
  fi

  aur_helper="$(find_aur_helper)"
  if [[ -z "$aur_helper" ]]; then
    warn "AUR helper (paru/yay) not found. Skipping AUR packages: ${aur_packages[*]}"
    return
  fi

  ok "Installing AUR packages via $aur_helper..."
  # use helper to install AUR packages non-interactively
  if [[ "$aur_helper" == "paru" ]]; then
    paru -S --noconfirm --needed "${aur_packages[@]}"
  else
    # yay
    yay -S --noconfirm --needed "${aur_packages[@]}"
  fi
}

aggregate_selections(){
  declare -A seen
  selected_packages=()
  for key in "${selected_category_keys[@]}"; do
    var="selected_packages_for_${key}[@]"
    eval "arr=(\"\${${var}:-}\")"
    for pkg in "${arr[@]}"; do
      [[ -z "$pkg" ]] && continue
      if [[ -z "${seen[$pkg]:-}" ]]; then selected_packages+=("$pkg"); seen[$pkg]=1; fi
    done
  done
}

confirm_and_install(){
  header "Final package list to install" >&2
  for p in "${selected_packages[@]}"; do printf " - %s\n" "$p" >&2; done
  echo >&2
  printf "%s" "$(prompt "Proceed with system update and install packages? (y/N): ")" >&2
  read -r ans
  if [[ "${ans,,}" == "y" ]]; then
    # split into repo and aur, then install
    split_repo_and_aur
    install_repo_packages
    install_aur_packages
    ok "Done."
  else
    warn "Installation cancelled."
  fi
}

trap 'err "Interrupted by user."; exit 1' INT

# main loop
while true; do
  select_categories

  back_requested=0
  for key in "${selected_category_keys[@]}"; do
    chosen_output="$(select_packages_for_category "$key")"
    rc=$?
    if [ "$rc" -eq 2 ]; then back_requested=1; break; fi
    mapfile -t chosen <<< "$chosen_output"
    eval "selected_packages_for_${key}=(\"\${chosen[@]}\")"
    ok "Selected for ${category_name[$key]}: ${chosen[*]:-(none)}"
  done

  if [ "$back_requested" -eq 1 ]; then
    continue
  fi

  aggregate_selections
  break
done

if [ "${#selected_packages[@]}" -eq 0 ]; then err "No packages selected. Exiting." ; exit 1; fi

confirm_and_install
exit 0
