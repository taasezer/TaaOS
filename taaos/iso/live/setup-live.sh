#!/bin/bash
#
# TaaOS Live Environment Setup
# Configures the live ISO environment
#

set -e

LIVE_DIR="/run/taaos/live"
WORK_DIR="/tmp/taaos-live-build"

echo "Building TaaOS Live Environment..."

# Create work directory
mkdir -p "$WORK_DIR"/{rootfs,iso}

# Copy base system
rsync -a /var/lib/taaos/rootfs/ "$WORK_DIR/rootfs/"

# Configure live user
chroot "$WORK_DIR/rootfs" useradd -m -G wheel,docker,audio,video -s /bin/zsh taaos
echo "taaos:taaos" | chroot "$WORK_DIR/rootfs" chpasswd

# Enable autologin
mkdir -p "$WORK_DIR/rootfs/etc/sddm.conf.d"
cat > "$WORK_DIR/rootfs/etc/sddm.conf.d/autologin.conf" <<EOF
[Autologin]
User=taaos
Session=plasma
EOF

# Add live-specific services
cat > "$WORK_DIR/rootfs/etc/systemd/system/taaos-live-setup.service" <<EOF
[Unit]
Description=TaaOS Live Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/taaos-welcome
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

chroot "$WORK_DIR/rootfs" systemctl enable taaos-live-setup

# Create squashfs
mksquashfs "$WORK_DIR/rootfs" "$WORK_DIR/iso/filesystem.squashfs" \
    -comp zstd -Xcompression-level 19 -b 1M

echo "Live environment created successfully!"
