#!/bin/bash

# --- Color Codes ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'

# --- Root Check ---
if [ "$EUID" -ne 0 ]; then
  echo -e "${C_YELLOW}Root privileges required. Rerunning with sudo...${C_RESET}"
  sudo bash "$0"
  exit
fi

# --- Function to remove existing swap configurations ---
remove_existing_swap() {
    echo -e "${C_BLUE}❯ Checking for existing swap configurations...${C_RESET}"
    swapoff -a &>/dev/null
    if lsmod | grep -q "^zram"; then
        echo -e "${C_YELLOW}  Unloading zram kernel module...${C_RESET}"
        rmmod zram
    fi
    rm -f /etc/systemd/zram-generator.conf
    if grep -q "swap" /etc/fstab; then
        echo -e "${C_YELLOW}  Removing swap entries from /etc/fstab...${C_RESET}"
        cp /etc/fstab /etc/fstab.bak."$(date +%s)"
        sed -i '/swap/d' /etc/fstab
    fi
}

# --- Function to enable overcommit if needed ---
enable_overcommit() {
    echo -e "${C_BLUE}❯ Checking kernel overcommit setting...${C_RESET}"
    CURRENT_OVERCOMMIT=$(sysctl vm.overcommit_memory | awk '{print $3}')
    if [ "$CURRENT_OVERCOMMIT" -ne 1 ]; then
        echo -e "${C_YELLOW}  Enabling memory overcommit to allow larger ZRAM (may increase OOM risk)...${C_RESET}"
        echo "vm.overcommit_memory = 1" > /etc/sysctl.d/99-zram-overcommit.conf
        sysctl --load=/etc/sysctl.d/99-zram-overcommit.conf
    else
        echo -e "${C_GREEN}  Overcommit already enabled.${C_RESET}"
    fi
}

# --- Main Logic ---
clear
echo -e "${C_BLUE}--- ZRAM Swap Setup ---${C_RESET}"
read -p "Create or re-create ZRAM swap? (y/n): " CREATE_SWAP

if [[ ! "$CREATE_SWAP" =~ ^[Yy]$ ]]; then
    echo -e "${C_YELLOW}Operation cancelled.${C_RESET}"
    exit 0
fi

remove_existing_swap

# --- Size Selection ---
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_GB=$((TOTAL_MEM_KB / 1024 / 1024))

echo -e "${C_BLUE}❯ Select ZRAM swap size (Total RAM: ${TOTAL_MEM_GB} GB):${C_RESET}"
echo "  1) 4 GB"
echo "  2) 8 GB"
echo "  3) 16 GB"
echo "  4) Custom size (in GB)"
read -p "Your choice [1-4]: " SIZE_OPTION

case $SIZE_OPTION in
    1) SWAP_SIZE_GB=4 ;;
    2) SWAP_SIZE_GB=8 ;;
    3) SWAP_SIZE_GB=16 ;;
    4) read -p "Enter desired size in GB: " SWAP_SIZE_GB ;;
    *) echo -e "${C_RED}Invalid option. Exiting.${C_RESET}"; exit 1 ;;
esac

if ! [[ "$SWAP_SIZE_GB" =~ ^[0-9]+$ ]] || [ "$SWAP_SIZE_GB" -le 0 ]; then
    echo -e "${C_RED}Error: Invalid size entered. Exiting.${C_RESET}"
    exit 1
fi

# --- Check for large size ---
if [ "$SWAP_SIZE_GB" -gt "$TOTAL_MEM_GB" ]; then
    echo -e "${C_YELLOW}Warning: ZRAM size larger than physical RAM may fail due to kernel memory limits for metadata.${C_RESET}"
    echo -e "${C_YELLOW}Recommended: <= 2x RAM (${TOTAL_MEM_GB}GB). Proceed? (y/n):${C_RESET}"
    read -p "" PROCEED
    if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
        echo -e "${C_YELLOW}Operation cancelled.${C_RESET}"
        exit 0
    fi
fi

# --- Estimate metadata and check available memory ---
EST_METADATA_MB=$((SWAP_SIZE_GB * 4))
MEM_AVAILABLE_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
MEM_AVAILABLE_MB=$((MEM_AVAILABLE_KB / 1024))

if [ "$EST_METADATA_MB" -gt "$MEM_AVAILABLE_MB" ]; then
    echo -e "${C_RED}Error: Not enough available memory for ZRAM metadata (~${EST_METADATA_MB}MB needed, ${MEM_AVAILABLE_MB}MB available). Free up memory and retry.${C_RESET}"
    exit 1
fi

enable_overcommit

# --- Setup ---
echo -e "${C_BLUE}❯ Configuring ZRAM...${C_RESET}"
if ! pacman -Q zram-generator &> /dev/null; then
    echo -e "${C_YELLOW}  Installing zram-generator...${C_RESET}"
    pacman -Syu --noconfirm zram-generator
fi

cat > /etc/systemd/zram-generator.conf << EOL
[zram0]
zram-size = ${SWAP_SIZE_GB}G
EOL

systemctl daemon-reload
systemctl restart systemd-zram-setup@zram0.service

# --- Verification ---
if systemctl is-active --quiet systemd-zram-setup@zram0.service; then
    echo -e "\n${C_GREEN}-------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}ZRAM swap successfully configured!${C_RESET}"
    echo -e "${C_GREEN}-------------------------------------------${C_RESET}"
    echo -e "Swap size: ${C_YELLOW}${SWAP_SIZE_GB} GB${C_RESET}"
    echo
    free -h
else
    echo -e "\n${C_RED}-------------------------------------------${C_RESET}"
    echo -e "${C_RED}An error occurred while starting the ZRAM service!${C_RESET}"
    echo -e "${C_RED}-------------------------------------------${C_RESET}"
    echo -e "${C_YELLOW}Please review the logs for diagnostics:${C_RESET}"
    journalctl -n 20 --no-pager -u systemd-zram-setup@zram0.service
fi

exit 0
