#!/bin/bash
set -e

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
W="\e[97m"
E="\e[0m"

info(){ printf "${B}%s${E}\n" "$*"; }
ok(){   printf "${G}%s${E}\n" "$*"; }
warn(){ printf "${Y}%s${E}\n" "$*"; }
err(){  printf "${R}%s${E}\n" "$*" >&2; }

info "Detecting GPU and preparing drivers for Hyprland..."

multilib_enabled() {
  grep -q "^\[multilib\]" /etc/pacman.conf
}

install_pkg() {
  local pkg="$1"
  echo -ne "${Y}Installing ${pkg}... "
  if sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
    ok "[OK]"
  else
    err "[FAILED]"
    FAILED_PKGS+=("$pkg")
  fi
}

FAILED_PKGS=()

GPU_INFO="$(lspci -nnk | grep -A3 -E 'VGA|3D|Display' || true)"
info "Detected adapters:"
echo "$GPU_INFO" | sed 's/^/  /'

HAS_NVIDIA=false
HAS_AMD=false
HAS_INTEL=false
IS_INTEL_ARC=false

echo "$GPU_INFO" | grep -qi 'NVIDIA'       && HAS_NVIDIA=true
echo "$GPU_INFO" | grep -qi 'AMD/ATI'      && HAS_AMD=true
echo "$GPU_INFO" | grep -qi 'Intel'        && HAS_INTEL=true
if $HAS_INTEL && echo "$GPU_INFO" | grep -qiE 'Arc|DG2|Alchemist'; then
  IS_INTEL_ARC=true
fi

if $HAS_NVIDIA; then
  info "NVIDIA GPU detected. Delegating to nvidia.sh..."
  if [ -x "$HOME/HyprArch/scripts/nvidia.sh" ]; then
    if ! "$HOME/HyprArch/scripts/nvidia.sh"; then
      err "nvidia.sh failed. Aborting."
      exit 1
    fi
  else
    warn "nvidia.sh is not executable; running with bash."
    if ! bash "$HOME/HyprArch/scripts/nvidia.sh"; then
      err "nvidia.sh failed. Aborting."
      exit 1
    fi
  fi

elif $HAS_AMD; then
  info "AMD GPU detected. Installing Mesa/Radeon stack..."
  AMD_PKGS=(mesa vulkan-radeon libva-mesa-driver vulkan-mesa-layers)
  if multilib_enabled; then
    AMD_PKGS+=(lib32-vulkan-radeon lib32-mesa)
  fi
  for p in "${AMD_PKGS[@]}"; do install_pkg "$p"; done

elif $HAS_INTEL; then
  if $IS_INTEL_ARC; then
    info "Intel Arc GPU detected. Installing Intel Vulkan/Media stack..."
  else
    info "Intel iGPU detected. Installing Intel Vulkan/Media stack..."
  fi
  INTEL_PKGS=(mesa vulkan-intel intel-media-driver vulkan-mesa-layers)
  if multilib_enabled; then
    INTEL_PKGS+=(lib32-vulkan-intel lib32-mesa)
  fi
  for p in "${INTEL_PKGS[@]}"; do install_pkg "$p"; done
else
  warn "No supported GPU vendor detected (NVIDIA/AMD/Intel). Skipping GPU driver setup."
fi
if [ "${#FAILED_PKGS[@]}" -gt 0 ]; then
  err "Some packages failed to install: ${FAILED_PKGS[*]}"
  warn "You may re-run this step after fixing mirrors/network or try again later."
  exit 1
fi

ok "GPU detection and driver setup completed successfully."
exit 0