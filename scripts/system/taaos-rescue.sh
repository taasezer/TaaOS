#!/bin/bash
# =============================================================================
# TaaOS System Rescue Tool
# =============================================================================
# Recovery utilities for system repair, backup, and restore
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/taaos/rescue.log"

# =============================================================================
# LOGGING
# =============================================================================
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; log "[INFO] $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; log "[SUCCESS] $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; log "[WARN] $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; log "[ERROR] $*"; }

# =============================================================================
# PREREQUISITES
# =============================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This tool requires root privileges"
        log_info "Try: sudo taaos-rescue"
        exit 1
    fi
}

check_dialog() {
    if ! command -v dialog &> /dev/null; then
        log_warn "dialog not installed, using text menu"
        return 1
    fi
    return 0
}

# =============================================================================
# MENU
# =============================================================================
show_menu_dialog() {
    dialog --clear --backtitle "TaaOS System Rescue Tool" \
        --title "Recovery Options" \
        --menu "Select a recovery action:" 18 60 7 \
        1 "Create System Snapshot" \
        2 "Restore from Snapshot" \
        3 "Repair Package Database" \
        4 "Repair Boot (GRUB)" \
        5 "Backup /home Directory" \
        6 "Emergency Shell" \
        7 "Exit" \
        2>&1 >/dev/tty
}

show_menu_text() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               TaaOS System Rescue Tool                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  [1] Create System Snapshot"
    echo "      → Save current system state for rollback"
    echo ""
    echo "  [2] Restore from Snapshot"
    echo "      → Restore to a previous system state"
    echo ""
    echo "  [3] Repair Package Database"
    echo "      → Fix broken packages and APT issues"
    echo ""
    echo "  [4] Repair Boot (GRUB)"
    echo "      → Fix boot problems"
    echo ""
    echo "  [5] Backup /home Directory"
    echo "      → Copy user data to external drive"
    echo ""
    echo "  [6] Emergency Shell"
    echo "      → Open root shell for manual repair"
    echo ""
    echo "  [7] Exit"
    echo ""
    read -p "Select option [1-7]: " choice
    echo "$choice"
}

# =============================================================================
# OPTION HANDLERS
# =============================================================================
create_snapshot() {
    log_info "Creating system snapshot..."
    
    if ! command -v timeshift &> /dev/null; then
        log_error "Timeshift is not installed"
        log_info "Install with: taaos-pkg install timeshift"
        return 1
    fi
    
    read -p "Enter snapshot comment (optional): " comment
    comment="${comment:-TaaOS manual snapshot}"
    
    log_info "Creating snapshot: $comment"
    timeshift --create --comments "$comment" --scripted
    
    log_success "Snapshot created successfully!"
}

restore_snapshot() {
    log_info "Listing available snapshots..."
    
    if ! command -v timeshift &> /dev/null; then
        log_error "Timeshift is not installed"
        return 1
    fi
    
    timeshift --list
    
    echo ""
    read -p "Enter snapshot ID to restore (or 'cancel'): " snapshot_id
    
    if [[ "$snapshot_id" == "cancel" ]]; then
        log_info "Restore cancelled"
        return 0
    fi
    
    log_warn "⚠️  WARNING: This will restore your system to a previous state!"
    log_warn "⚠️  Current system state will be replaced!"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log_info "Restore cancelled"
        return 0
    fi
    
    log_info "Restoring snapshot: $snapshot_id"
    timeshift --restore --snapshot "$snapshot_id" --scripted
    
    log_success "Snapshot restored! Please reboot."
}

repair_packages() {
    log_info "Repairing package database..."
    
    # Step 1: Configure any partially installed packages
    log_info "Step 1/4: Configuring pending packages..."
    dpkg --configure -a || true
    
    # Step 2: Fix broken dependencies
    log_info "Step 2/4: Fixing broken dependencies..."
    apt-get install -f -y || true
    
    # Step 3: Update package lists
    log_info "Step 3/4: Updating package lists..."
    apt-get update || true
    
    # Step 4: Check package integrity
    log_info "Step 4/4: Checking package integrity..."
    apt-get check
    
    log_success "Package database repair complete!"
}

repair_boot() {
    log_info "Repairing boot configuration..."
    
    # Detect boot disk
    local boot_disk
    boot_disk=$(lsblk -dpno NAME,TYPE | grep disk | head -1 | awk '{print $1}')
    
    log_info "Detected boot disk: $boot_disk"
    
    log_warn "⚠️  WARNING: This will reinstall GRUB to $boot_disk"
    read -p "Is this correct? Type 'yes' to confirm: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        read -p "Enter correct disk (e.g., /dev/sda): " boot_disk
    fi
    
    # Reinstall GRUB
    log_info "Installing GRUB to $boot_disk..."
    grub-install "$boot_disk"
    
    # Update GRUB config
    log_info "Updating GRUB configuration..."
    update-grub
    
    log_success "Boot repair complete!"
}

backup_home() {
    log_info "Backup /home directory..."
    
    # List available devices
    log_info "Available destinations:"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v loop
    
    echo ""
    read -p "Enter backup destination (e.g., /media/usb or /mnt/backup): " target
    
    if [[ ! -d "$target" ]]; then
        log_error "Destination does not exist: $target"
        read -p "Do you want to create it? [y/N]: " create
        if [[ "$create" =~ ^[Yy]$ ]]; then
            mkdir -p "$target"
        else
            return 1
        fi
    fi
    
    # Check available space
    local home_size
    local target_avail
    home_size=$(du -sb /home 2>/dev/null | awk '{print $1}')
    target_avail=$(df -B1 "$target" | tail -1 | awk '{print $4}')
    
    if [[ $home_size -gt $target_avail ]]; then
        log_error "Not enough space on destination!"
        log_error "/home size: $(numfmt --to=iec $home_size)"
        log_error "Available: $(numfmt --to=iec $target_avail)"
        return 1
    fi
    
    # Create backup
    local backup_dir="$target/taaos-home-backup-$(date +%Y%m%d-%H%M%S)"
    log_info "Creating backup at: $backup_dir"
    
    rsync -avh --progress /home/ "$backup_dir/"
    
    log_success "Backup complete!"
    log_info "Backup location: $backup_dir"
}

emergency_shell() {
    log_warn "Opening emergency shell..."
    log_warn "Type 'exit' to return to rescue menu"
    echo ""
    
    # Log session start
    log "[EMERGENCY] Shell session started by $(whoami)"
    
    # Start shell
    bash
    
    # Log session end
    log "[EMERGENCY] Shell session ended"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    check_root
    
    while true; do
        local choice
        
        if check_dialog 2>/dev/null; then
            choice=$(show_menu_dialog) || break
        else
            choice=$(show_menu_text)
        fi
        
        clear
        
        case "$choice" in
            1) create_snapshot ;;
            2) restore_snapshot ;;
            3) repair_packages ;;
            4) repair_boot ;;
            5) backup_home ;;
            6) emergency_shell ;;
            7|"") break ;;
            *) log_error "Invalid option: $choice" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
    
    clear
    log_info "TaaOS Rescue Tool exited"
}

# Handle --help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "TaaOS System Rescue Tool"
    echo ""
    echo "Usage: taaos-rescue"
    echo ""
    echo "Interactive tool for system recovery:"
    echo "  - Create/restore snapshots (Timeshift)"
    echo "  - Repair package database"
    echo "  - Fix boot problems"
    echo "  - Backup user data"
    exit 0
fi

main "$@"
