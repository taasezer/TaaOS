#!/bin/bash
# =============================================================================
# TaaOS Persistent USB Creator
# =============================================================================
# Creates a bootable USB with persistence partition
# =============================================================================
# SECURITY: This script handles disk operations - use with caution
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
BOOT_LABEL="TAAOS_BOOT"
PERSIST_LABEL="TAAOS_PERSIST"
ISO_PATH=""
USB_DEVICE=""

# =============================================================================
# SAFETY CHECKS
# =============================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    local deps=("parted" "mkfs.vfat" "mkfs.ext4" "dd" "lsblk")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Required command not found: $dep"
            exit 1
        fi
    done
}

validate_device() {
    local device="$1"
    
    # Safety: Refuse to operate on /dev/sda (usually system disk)
    if [[ "$device" == "/dev/sda" ]]; then
        log_error "SAFETY: Refusing to operate on /dev/sda (likely system disk)"
        log_error "If you really want to use /dev/sda, use --force-sda flag"
        exit 1
    fi
    
    # Check if device exists
    if [[ ! -b "$device" ]]; then
        log_error "Device not found: $device"
        exit 1
    fi
    
    # Check if device is mounted
    if mount | grep -q "^$device"; then
        log_error "Device $device is currently mounted!"
        log_error "Unmount all partitions first: umount ${device}*"
        exit 1
    fi
    
    # Check if any partition is mounted
    if mount | grep -q "^${device}[0-9]"; then
        log_error "One or more partitions on $device are mounted!"
        log_error "Unmount all partitions first"
        exit 1
    fi
    
    log_success "Device validation passed: $device"
}

# =============================================================================
# DEVICE SELECTION
# =============================================================================
list_usb_devices() {
    log_info "Available USB devices:"
    echo ""
    lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -E "usb|NAME" || true
    echo ""
}

select_device() {
    list_usb_devices
    
    read -p "Enter device name (e.g., sdb): " device_name
    USB_DEVICE="/dev/${device_name}"
    
    validate_device "$USB_DEVICE"
}

select_iso() {
    if [[ -n "${1:-}" ]] && [[ -f "$1" ]]; then
        ISO_PATH="$1"
    else
        read -p "Enter path to TaaOS ISO file: " ISO_PATH
    fi
    
    if [[ ! -f "$ISO_PATH" ]]; then
        log_error "ISO file not found: $ISO_PATH"
        exit 1
    fi
    
    log_success "ISO file: $ISO_PATH"
}

# =============================================================================
# CONFIRMATION
# =============================================================================
confirm_operation() {
    echo ""
    log_warn "╔══════════════════════════════════════════════════════════════╗"
    log_warn "║                    ⚠️  WARNING ⚠️                              ║"
    log_warn "╠══════════════════════════════════════════════════════════════╣"
    log_warn "║  ALL DATA ON $USB_DEVICE WILL BE PERMANENTLY DESTROYED!"
    log_warn "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Device: $USB_DEVICE"
    log_info "ISO: $ISO_PATH"
    echo ""
    
    read -p "Type 'YES' to confirm: " confirmation
    
    if [[ "$confirmation" != "YES" ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
    
    # Double confirmation for safety
    read -p "Are you absolutely sure? (yes/no): " final_confirm
    
    if [[ "$final_confirm" != "yes" ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
}

# =============================================================================
# USB CREATION
# =============================================================================
create_partitions() {
    log_info "Creating partition table on $USB_DEVICE..."
    
    # Create GPT partition table
    parted -s "$USB_DEVICE" mklabel gpt
    
    # Partition 1: Boot (FAT32, 4GB)
    parted -s "$USB_DEVICE" mkpart primary fat32 1MiB 4GiB
    parted -s "$USB_DEVICE" set 1 boot on
    parted -s "$USB_DEVICE" set 1 esp on
    
    # Partition 2: Persistence (EXT4, remaining space)
    parted -s "$USB_DEVICE" mkpart primary ext4 4GiB 100%
    
    # Wait for kernel to recognize partitions
    sleep 2
    partprobe "$USB_DEVICE" || true
    sleep 1
    
    log_success "Partitions created"
}

format_partitions() {
    log_info "Formatting partitions..."
    
    # Format boot partition
    mkfs.vfat -F 32 -n "$BOOT_LABEL" "${USB_DEVICE}1"
    
    # Format persistence partition
    mkfs.ext4 -L "$PERSIST_LABEL" "${USB_DEVICE}2"
    
    log_success "Partitions formatted"
}

write_iso() {
    log_info "Writing ISO to boot partition..."
    log_warn "This may take several minutes..."
    
    # Mount boot partition
    local mount_point="/tmp/taaos_usb_boot_$$"
    mkdir -p "$mount_point"
    mount "${USB_DEVICE}1" "$mount_point"
    
    # Extract ISO contents (not dd, we need to add persistence config)
    if command -v 7z &> /dev/null; then
        7z x -o"$mount_point" "$ISO_PATH"
    elif command -v bsdtar &> /dev/null; then
        bsdtar -xf "$ISO_PATH" -C "$mount_point"
    else
        # Fallback: mount ISO and copy
        local iso_mount="/tmp/taaos_iso_$$"
        mkdir -p "$iso_mount"
        mount -o loop "$ISO_PATH" "$iso_mount"
        cp -r "$iso_mount"/* "$mount_point/"
        umount "$iso_mount"
        rmdir "$iso_mount"
    fi
    
    log_success "ISO contents extracted"
    
    # Add persistence configuration to GRUB
    configure_grub_persistence "$mount_point"
    
    # Unmount
    umount "$mount_point"
    rmdir "$mount_point"
    
    log_success "ISO written successfully"
}

configure_grub_persistence() {
    local mount_point="$1"
    local grub_cfg="$mount_point/boot/grub/grub.cfg"
    
    if [[ -f "$grub_cfg" ]]; then
        log_info "Adding persistence boot option to GRUB..."
        
        # Backup original
        cp "$grub_cfg" "${grub_cfg}.bak"
        
        # Add persistence parameter to existing entries
        sed -i 's/boot=live/boot=live persistence persistence-label=TAAOS_PERSIST/g' "$grub_cfg"
        
        log_success "GRUB configured for persistence"
    else
        log_warn "GRUB config not found at expected location"
    fi
}

setup_persistence_partition() {
    log_info "Setting up persistence partition..."
    
    local mount_point="/tmp/taaos_persist_$$"
    mkdir -p "$mount_point"
    mount "${USB_DEVICE}2" "$mount_point"
    
    # Create persistence.conf
    echo "/ union" > "$mount_point/persistence.conf"
    
    # Create necessary directories
    mkdir -p "$mount_point/rw"
    mkdir -p "$mount_point/work"
    
    umount "$mount_point"
    rmdir "$mount_point"
    
    log_success "Persistence partition configured"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         TaaOS Persistent USB Creator                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    check_root
    check_dependencies
    
    select_iso "${1:-}"
    select_device
    confirm_operation
    
    log_info "Starting USB creation..."
    
    create_partitions
    format_partitions
    write_iso
    setup_persistence_partition
    
    echo ""
    log_success "╔══════════════════════════════════════════════════════════════╗"
    log_success "║         TaaOS Persistent USB Created Successfully!           ║"
    log_success "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Boot partition: ${USB_DEVICE}1 ($BOOT_LABEL)"
    log_info "Persistence partition: ${USB_DEVICE}2 ($PERSIST_LABEL)"
    echo ""
    log_info "You can now boot from this USB drive."
    log_info "All changes will be saved to the persistence partition."
}

# Handle --help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [ISO_PATH]"
    echo ""
    echo "Creates a bootable TaaOS USB drive with persistence support."
    echo ""
    echo "Options:"
    echo "  ISO_PATH    Path to TaaOS ISO file (optional, will prompt if not provided)"
    echo "  --help      Show this help message"
    exit 0
fi

main "$@"
