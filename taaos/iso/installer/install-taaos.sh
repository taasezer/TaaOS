#!/bin/bash
#
# TaaOS ISO Installer
# Installs TaaOS to disk from live environment
#

set -e

INSTALL_DISK=""
ROOT_PART=""
BOOT_PART=""
HOSTNAME="taaos"
USERNAME="taaos"

show_welcome() {
    clear
    echo "========================================="
    echo "   TaaOS Installer"
    echo "   The Developer's Operating System"
    echo "========================================="
    echo ""
}

select_disk() {
    echo "Available disks:"
    lsblk -d -n -o NAME,SIZE,TYPE | grep disk
    echo ""
    read -p "Select installation disk (e.g., sda): " INSTALL_DISK
    
    if [ ! -b "/dev/$INSTALL_DISK" ]; then
        echo "Error: Invalid disk"
        exit 1
    fi
}

partition_disk() {
    echo "Partitioning /dev/$INSTALL_DISK..."
    
    # Create GPT partition table
    parted -s "/dev/$INSTALL_DISK" mklabel gpt
    
    # Create EFI partition (512MB)
    parted -s "/dev/$INSTALL_DISK" mkpart ESP fat32 1MiB 513MiB
    parted -s "/dev/$INSTALL_DISK" set 1 esp on
    
    # Create root partition (remaining space)
    parted -s "/dev/$INSTALL_DISK" mkpart primary btrfs 513MiB 100%
    
    BOOT_PART="/dev/${INSTALL_DISK}1"
    ROOT_PART="/dev/${INSTALL_DISK}2"
    
    # Format partitions
    mkfs.fat -F32 "$BOOT_PART"
    mkfs.btrfs -f "$ROOT_PART"
}

mount_partitions() {
    echo "Mounting partitions..."
    
    # Mount root
    mount "$ROOT_PART" /mnt
    
    # Create btrfs subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    
    # Remount with subvolumes
    umount /mnt
    mount -o subvol=@,compress=zstd,noatime "$ROOT_PART" /mnt
    mkdir -p /mnt/{home,boot,.snapshots}
    mount -o subvol=@home,compress=zstd,noatime "$ROOT_PART" /mnt/home
    mount -o subvol=@snapshots "$ROOT_PART" /mnt/.snapshots
    mount "$BOOT_PART" /mnt/boot
}

install_system() {
    echo "Installing TaaOS..."
    
    # Copy system files
    rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / /mnt/
    
    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

configure_system() {
    echo "Configuring system..."
    
    # Set hostname
    echo "$HOSTNAME" > /mnt/etc/hostname
    
    # Set locale
    echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
    
    # Set timezone
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    arch-chroot /mnt hwclock --systohc
    
    # Create user
    arch-chroot /mnt useradd -m -G wheel,docker,audio,video -s /bin/zsh "$USERNAME"
    echo "$USERNAME:taaos" | arch-chroot /mnt chpasswd
    
    # Enable sudo
    echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
}

install_bootloader() {
    echo "Installing bootloader..."
    
    # Install GRUB
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=TaaOS
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

finalize() {
    echo "Finalizing installation..."
    
    # Enable services
    arch-chroot /mnt systemctl enable NetworkManager
    arch-chroot /mnt systemctl enable sddm
    arch-chroot /mnt systemctl enable taaos-neural-engine
    arch-chroot /mnt systemctl enable taaos-brain
    arch-chroot /mnt systemctl enable docker
    
    # Unmount
    umount -R /mnt
    
    echo ""
    echo "========================================="
    echo "   Installation Complete!"
    echo "========================================="
    echo "Remove installation media and reboot"
}

# Main installation flow
show_welcome
select_disk
partition_disk
mount_partitions
install_system
configure_system
install_bootloader
finalize
