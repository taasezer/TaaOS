#!/bin/bash
set -euo pipefail

DISTRIBUTION="bookworm"
IMAGE_NAME="TaaOS"

echo "=============================================="
echo "[CONFIG] TaaOS Live-Build Configuration"
echo "=============================================="

# TaaOS Live-Build Configuration - FIXED for VM/EFI Boot
# Custom kernel is injected via packages.chroot and kernel hook
lb config \
    --distribution "${DISTRIBUTION}" \
    --architecture "amd64" \
    --archive-areas "main contrib non-free non-free-firmware" \
    --bootloader "grub-efi" \
    --bootloaders "grub-efi,grub-pc" \
    --binary-images "iso-hybrid" \
    --image-name "${IMAGE_NAME}" \
    --debian-installer "none" \
    --linux-packages "none" \
    --linux-flavours "" \
    --bootappend-live "boot=live components quiet splash" \
    --memtest "none" \
    --apt-options "--yes -o APT::Sandbox::User=root" \
    --apt-secure "false" \
    --mirror-bootstrap "http://deb.debian.org/debian" \
    --mirror-binary "http://deb.debian.org/debian" \
    --parent-mirror-bootstrap "http://deb.debian.org/debian" \
    --parent-mirror-binary "http://deb.debian.org/debian" \
    --parent-mirror-chroot-security "http://security.debian.org/debian-security" \
    --mirror-chroot-security "http://security.debian.org/debian-security" \
    --parent-mirror-binary-security "http://security.debian.org/debian-security" \
    --mirror-binary-security "http://security.debian.org/debian-security" \
    --win32-loader false \
    --loadlin false

# Copy custom bootloader configurations
echo "[CONFIG] Copying custom bootloader configs..."
mkdir -p config/includes.binary/boot/grub
mkdir -p config/includes.binary/EFI/boot
mkdir -p config/includes.chroot_after_packages/boot/efi

if [ -d "config/bootloaders" ]; then
    cp -r config/bootloaders/* config/includes.binary/ 2>/dev/null || true
    cp -r config/bootloaders/grub-efi/* config/includes.binary/boot/grub/ 2>/dev/null || true
    cp -r config/bootloaders/grub-efi/* config/includes.binary/EFI/boot/ 2>/dev/null || true
fi

# Set proper permissions for packages
echo "[CONFIG] Setting permissions for custom packages..."
chmod -R 755 config/packages.chroot/ 2>/dev/null || true

# Create EFI directory structure in chroot
echo "[CONFIG] Creating EFI directory structure..."
mkdir -p config/includes.chroot_after_packages/boot/efi/EFI/boot
mkdir -p config/includes.chroot_after_packages/efi/boot

# Create system directories
echo "[CONFIG] Creating system directories..."
mkdir -p config/includes.chroot/etc
mkdir -p config/includes.chroot/usr/lib/taaos
mkdir -p config/includes.chroot/var/log/taaos
mkdir -p config/includes.chroot/var/lib/taaos

# Create first-boot marker directory
touch config/includes.chroot/var/lib/taaos/.gitkeep

echo "=============================================="
echo "[CONFIG] TaaOS configuration complete!"
echo "=============================================="
echo ""
echo "System configured for:"
echo "  - Full disk installation"
echo "  - EFI and BIOS boot support"
echo "  - LVM, RAID, and encryption"
echo "  - Hardware auto-detection"
echo "  - Development environment"
echo ""