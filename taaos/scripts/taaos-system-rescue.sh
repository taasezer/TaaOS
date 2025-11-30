#!/bin/bash
#
# TaaOS System Rescue
# Emergency recovery and repair toolkit
#

set -e

RESCUE_LOG="/var/log/taaos/rescue.log"
mkdir -p "$(dirname $RESCUE_LOG)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$RESCUE_LOG"
}

show_menu() {
    clear
    echo "========================================="
    echo "   TaaOS System Rescue & Recovery"
    echo "========================================="
    echo ""
    echo "1. Repair Bootloader (GRUB)"
    echo "2. Fix Filesystem Errors"
    echo "3. Reset Network Configuration"
    echo "4. Restore from Snapshot"
    echo "5. Rebuild Initramfs"
    echo "6. Fix Package Database"
    echo "7. Reset User Permissions"
    echo "8. Emergency Shell"
    echo "9. System Diagnostics"
    echo "0. Exit"
    echo ""
    read -p "Select option: " choice
    echo ""
}

repair_bootloader() {
    log "Repairing GRUB bootloader..."
    
    # Detect boot partition
    BOOT_PART=$(df /boot | tail -1 | awk '{print $1}')
    ROOT_PART=$(df / | tail -1 | awk '{print $1}')
    
    log "Boot partition: $BOOT_PART"
    log "Root partition: $ROOT_PART"
    
    # Reinstall GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=TaaOS
    grub-mkconfig -o /boot/grub/grub.cfg
    
    log "Bootloader repaired successfully"
}

fix_filesystem() {
    log "Checking filesystem integrity..."
    
    # Get all partitions
    PARTITIONS=$(lsblk -nlo NAME,FSTYPE | grep -E 'ext4|btrfs|xfs' | awk '{print "/dev/"$1}')
    
    for part in $PARTITIONS; do
        log "Checking $part..."
        
        # Unmount if mounted
        if mount | grep -q "$part"; then
            umount "$part" 2>/dev/null || true
        fi
        
        # Run filesystem check
        fstype=$(lsblk -no FSTYPE "$part")
        case $fstype in
            ext4)
                e2fsck -fy "$part"
                ;;
            btrfs)
                btrfs check --repair "$part"
                ;;
            xfs)
                xfs_repair "$part"
                ;;
        esac
    done
    
    log "Filesystem check completed"
}

reset_network() {
    log "Resetting network configuration..."
    
    # Stop NetworkManager
    systemctl stop NetworkManager
    
    # Remove old connections
    rm -rf /etc/NetworkManager/system-connections/*
    
    # Reset DNS
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    
    # Restart NetworkManager
    systemctl start NetworkManager
    
    log "Network configuration reset"
}

restore_snapshot() {
    log "Available Btrfs snapshots:"
    
    # List snapshots
    if [ -d "/.snapshots" ]; then
        ls -1 /.snapshots/
        echo ""
        read -p "Enter snapshot name to restore: " snapshot
        
        if [ -d "/.snapshots/$snapshot" ]; then
            log "Restoring from snapshot: $snapshot"
            
            # Create backup of current state
            btrfs subvolume snapshot / "/.snapshots/pre-restore-$(date +%Y%m%d-%H%M%S)"
            
            # Restore
            btrfs subvolume delete /
            btrfs subvolume snapshot "/.snapshots/$snapshot" /
            
            log "Snapshot restored. Please reboot."
        else
            log "Snapshot not found"
        fi
    else
        log "No snapshots directory found"
    fi
}

rebuild_initramfs() {
    log "Rebuilding initramfs..."
    
    # Get kernel version
    KERNEL_VERSION=$(uname -r)
    
    log "Kernel version: $KERNEL_VERSION"
    
    # Rebuild
    mkinitcpio -p linux-taakernel
    
    log "Initramfs rebuilt successfully"
}

fix_package_db() {
    log "Repairing package database..."
    
    # Remove locks
    rm -f /var/lib/pacman/db.lck
    
    # Sync databases
    taapac -Sy
    
    # Check for broken packages
    taapac -Qk
    
    log "Package database repaired"
}

reset_permissions() {
    log "Resetting user permissions..."
    
    read -p "Enter username: " username
    
    if id "$username" &>/dev/null; then
        # Reset home directory permissions
        chown -R "$username:$username" "/home/$username"
        chmod 755 "/home/$username"
        
        # Reset common directories
        chmod 700 "/home/$username/.ssh" 2>/dev/null || true
        chmod 600 "/home/$username/.ssh/"* 2>/dev/null || true
        
        log "Permissions reset for user: $username"
    else
        log "User not found: $username"
    fi
}

emergency_shell() {
    log "Starting emergency shell..."
    echo "Type 'exit' to return to rescue menu"
    bash
}

system_diagnostics() {
    log "Running system diagnostics..."
    
    echo "=== SYSTEM DIAGNOSTICS ==="
    echo ""
    
    echo "Kernel:"
    uname -a
    echo ""
    
    echo "Disk Usage:"
    df -h
    echo ""
    
    echo "Memory:"
    free -h
    echo ""
    
    echo "Failed Services:"
    systemctl --failed
    echo ""
    
    echo "Recent Errors:"
    journalctl -p 3 -n 20 --no-pager
    echo ""
    
    read -p "Press Enter to continue..."
}

# Main loop
while true; do
    show_menu
    
    case $choice in
        1) repair_bootloader ;;
        2) fix_filesystem ;;
        3) reset_network ;;
        4) restore_snapshot ;;
        5) rebuild_initramfs ;;
        6) fix_package_db ;;
        7) reset_permissions ;;
        8) emergency_shell ;;
        9) system_diagnostics ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
