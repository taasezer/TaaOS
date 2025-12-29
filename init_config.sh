#!/bin/bash
set -euo pipefail

DISTRIBUTION="bookworm"
IMAGE_NAME="TaaOS"

# TaaOS Live-Build Configuration
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
    --apt-secure "false"

# Copy custom bootloader configurations
echo "[CONFIG] Copying custom bootloader configs..."
if [ -d "config/bootloaders" ]; then
    cp -r config/bootloaders/* config/includes.binary/ 2>/dev/null || true
fi

echo "[CONFIG] live-build configured for TaaOS with custom kernel"