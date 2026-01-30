#!/bin/bash
# =============================================================================
# TaaOS Live-Build Configuration
# =============================================================================
# Phase 1 Hardening: Logging and validation
# =============================================================================
set -euo pipefail

# =============================================================================
# SOURCE COMMON LIBRARY IF AVAILABLE
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/scripts/lib/common.sh" ]]; then
    source "${SCRIPT_DIR}/scripts/lib/common.sh"
elif [[ -f "/build/scripts/lib/common.sh" ]]; then
    source "/build/scripts/lib/common.sh"
else
    log_info() { echo "[INFO] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_success() { echo "[SUCCESS] $*"; }
    log_phase() { echo ""; echo "=== $1 ==="; echo ""; }
fi

DISTRIBUTION="bookworm"
IMAGE_NAME="TaaOS"

log_phase "TaaOS Live-Build Configuration"
log_info "Distribution: ${DISTRIBUTION}"
log_info "Image name: ${IMAGE_NAME}"

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
    --linux-packages "linux-image" \
    --linux-flavours "amd64" \
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

if [ -d "config/bootloaders" ]; then
    cp -r config/bootloaders/* config/includes.binary/ 2>/dev/null || true
    cp -r config/bootloaders/grub-efi/* config/includes.binary/boot/grub/ 2>/dev/null || true
    cp -r config/bootloaders/grub-efi/* config/includes.binary/EFI/boot/ 2>/dev/null || true
fi

# Set proper permissions for packages
echo "[CONFIG] Setting permissions for custom packages..."
chmod -R 755 config/packages.chroot/ 2>/dev/null || true

# Create EFI directory structure in chroot (FIXED: use includes.chroot only)
echo "[CONFIG] Creating EFI directory structure..."
mkdir -p config/includes.chroot/boot/efi/EFI/boot
mkdir -p config/includes.chroot/efi/boot

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