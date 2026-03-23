#!/bin/bash
# =============================================================================
# TaaOS Persistence Mode Selector
# =============================================================================
# Interactive menu for selecting persistence mode
# =============================================================================

set -euo pipefail

# Source common library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
    source "${SCRIPT_DIR}/../lib/common.sh"
else
    log_info() { echo "[INFO] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_success() { echo "[SUCCESS] $*"; }
fi

# =============================================================================
# CONFIGURATION
# =============================================================================
CALAMARES_BIN="/usr/bin/calamares"
PERSISTENT_USB_SCRIPT="$(command -v taaos-create-persistent-usb || echo "${SCRIPT_DIR}/taaos-create-persistent-usb.sh")"
# If installed without .sh in the same directory, use that
if [[ ! -x "$PERSISTENT_USB_SCRIPT" && -x "${SCRIPT_DIR}/taaos-create-persistent-usb" ]]; then
    PERSISTENT_USB_SCRIPT="${SCRIPT_DIR}/taaos-create-persistent-usb"
fi

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_dialog() {
    if ! command -v dialog &> /dev/null; then
        log_error "dialog is required but not installed"
        log_info "Install with: apt install dialog"
        exit 1
    fi
}

# =============================================================================
# MENU DISPLAY
# =============================================================================
show_menu() {
    dialog --clear --backtitle "TaaOS Persistence Configuration" \
        --title "Select Persistence Mode" \
        --menu "Choose how TaaOS should handle data persistence:" 18 70 5 \
        1 "Full Installation (Recommended) - Install to disk" \
        2 "Persistent Live USB - Portable system with saved data" \
        3 "Hybrid Mode - Persistent /home, clean system" \
        4 "Pure Live Mode - No persistence (demo/testing)" \
        5 "Exit - Return to system" \
        2>&1 >/dev/tty
}

# =============================================================================
# MODE HANDLERS
# =============================================================================
do_full_install() {
    clear
    log_info "Launching Calamares installer..."
    
    if [[ -x "$CALAMARES_BIN" ]]; then
        "$CALAMARES_BIN"
    else
        log_error "Calamares installer not found at $CALAMARES_BIN"
        log_info "Falling back to text-based installer..."
        # TODO: Implement text-based installer fallback
        dialog --msgbox "Calamares installer not available.\n\nPlease use 'taaos-install' for command-line installation." 10 50
    fi
}

do_persistent_usb() {
    clear
    log_info "Launching Persistent USB Creator..."
    
    if [[ -x "$PERSISTENT_USB_SCRIPT" ]]; then
        "$PERSISTENT_USB_SCRIPT"
    else
        log_error "Persistent USB script not found"
        dialog --msgbox "Persistent USB creator not found.\n\nPlease run 'taaos-create-persistent-usb' manually." 10 50
    fi
}

do_hybrid_mode() {
    clear
    log_info "Configuring Hybrid Mode..."
    
    dialog --msgbox "Hybrid Mode Configuration\n\n\
This mode keeps /home persistent while resetting\n\
the system (/) on each boot.\n\n\
Requirements:\n\
- Separate partition for /home\n\
- Add 'persistence persistence-path=/home' to boot params\n\n\
This feature requires manual partition setup." 16 60
    
    # TODO: Implement automatic hybrid mode setup
    log_warn "Hybrid mode requires manual configuration"
}

do_pure_live() {
    clear
    log_info "Pure Live Mode selected"
    
    dialog --msgbox "Pure Live Mode\n\n\
No data will be persisted between reboots.\n\
This is ideal for:\n\
- Demo/Testing purposes\n\
- Secure browsing sessions\n\
- Troubleshooting\n\n\
All changes will be lost on reboot." 14 50
    
    log_success "Pure Live Mode - no configuration needed"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    check_root
    check_dialog
    
    while true; do
        choice=$(show_menu) || break
        
        case $choice in
            1) do_full_install ;;
            2) do_persistent_usb ;;
            3) do_hybrid_mode ;;
            4) do_pure_live ;;
            5) break ;;
            *) log_error "Invalid selection" ;;
        esac
    done
    
    clear
    log_success "TaaOS Persistence Configuration complete"
}

main "$@"
