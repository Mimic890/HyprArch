#!/usr/bin/env bash
set -euo pipefail

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

ORIG_USER="${SUDO_USER:-${USER:-$(id -un)}}"
ORIG_HOME="$(eval echo "~$ORIG_USER")"

SCRIPT_PATH="${ORIG_HOME}/HyprArch/install_scripts/replace-os-release.sh"

echo
info "#############################################"
info "##  Replace /etc/os-release with HyprArch  ##"
info "#############################################"

if [ ! -f "$SCRIPT_PATH" ]; then
    err "Replacement script not found at: $SCRIPT_PATH"
    warn "Please place replace-os-release.sh at that location or update SCRIPT_PATH."
    read -rp "$(echo -e "${Y}Skip this step and continue main installation? (y/N): ${E}")" _skip
    if [[ "$_skip" =~ ^[Yy]$ ]]; then
        warn "Skipping os-release replacement step."
        return 0 2>/dev/null || exit 0
    else
        err "Aborting — replacement script missing."
        exit 1
    fi
fi

CUSTOM_OS_RELEASE="$ORIG_HOME/HyprArch/customs/os-release"
if [ -f "$CUSTOM_OS_RELEASE" ]; then
    read -rp "$(echo -e "${B}Do you want to preview the custom os-release file before running the replacement? (y/N): ${E}")" _pv
    if [[ "$_pv" =~ ^[Yy]$ ]]; then
        echo
        info "---- Start of ${CUSTOM_OS_RELEASE} ----"
        sed -n '1,200p' "$CUSTOM_OS_RELEASE" || true
        info "---- End of preview ----"
        echo
        read -rp "$(echo -e "${Y}Continue to run the replacement script now? (y/N): ${E}")" _cont_after_preview
        if [[ ! "$_cont_after_preview" =~ ^[Yy]$ ]]; then
            warn "User cancelled after preview. Skipping os-release replacement."
            return 0 2>/dev/null || exit 0
        fi
    fi
else
    warn "Custom os-release file not found at: $CUSTOM_OS_RELEASE"
    read -rp "$(echo -e "${Y}Proceed to run the replacement script anyway? (y/N): ${E}")" _proceed_no_src
    if [[ ! "$_proceed_no_src" =~ ^[Yy]$ ]]; then
        warn "Skipping os-release replacement."
        return 0 2>/dev/null || exit 0
    fi
fi

read -rp "$(echo -e "${B}Run the os-release replacement script now? (y/N): ${E}")" _run
if [[ ! "$_run" =~ ^[Yy]$ ]]; then
    warn "User chose not to run the replacement script. Skipping."
    return 0 2>/dev/null || exit 0
fi

info "Launching: ${SCRIPT_PATH}"
echo
if [ -x "$SCRIPT_PATH" ]; then
    "$SCRIPT_PATH"
    EXIT_CODE=$?
else
    bash "$SCRIPT_PATH"
    EXIT_CODE=$?
fi

if [ "$EXIT_CODE" -eq 0 ]; then
    ok "os-release replacement script completed successfully."
else
    err "os-release replacement script exited with code ${EXIT_CODE}."
    read -rp "$(echo -e "${Y}Do you want to continue the main installation despite this error? (y/N): ${E}")" _continue_on_error
    if [[ "$_continue_on_error" =~ ^[Yy]$ ]]; then
        warn "Continuing main installation despite os-release failure."
    else
        err "Aborting main installation as requested."
        exit "$EXIT_CODE"
    fi
fi

echo
ok "Finished os-release replacement step."
