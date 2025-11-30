#!/bin/bash
#
# TaaOS Full System Builder
# Builds complete TaaOS from kernel to userspace
#

set -e

BUILD_DIR="$(pwd)/taaos-full-build"
KERNEL_SRC="$(pwd)"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              TaaOS Full System Builder                      ║"
echo "║         Building Complete Custom Operating System           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"/{kernel,rootfs,iso}

# Phase 1: Build Kernel
echo "═══ Phase 1: Building TaaOS Kernel ═══"
./scripts/integrate-kernel.sh

# Phase 2: Create Root Filesystem
echo ""
echo "═══ Phase 2: Creating Root Filesystem ═══"

ROOTFS="$BUILD_DIR/rootfs"
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp,var,usr,home,root}
mkdir -p "$ROOTFS"/usr/{bin,sbin,lib,share}
mkdir -p "$ROOTFS"/var/{log,lib,cache}

# Copy TaaOS components
echo "Installing TaaOS components..."
cp -r taaos/bin/* "$ROOTFS/usr/bin/" 2>/dev/null || true
cp -r taaos/system/* "$ROOTFS/usr/lib/taaos/" 2>/dev/null || true
cp -r taaos/config/* "$ROOTFS/etc/" 2>/dev/null || true
cp -r taaos/desktop/* "$ROOTFS/usr/share/taaos/" 2>/dev/null || true

# Create essential files
cat > "$ROOTFS/etc/os-release" <<EOF
NAME="TaaOS"
VERSION="1.0"
ID=taaos
ID_LIKE=arch
PRETTY_NAME="TaaOS - AI-Powered Operating System"
ANSI_COLOR="0;31"
HOME_URL="https://github.com/tahasezer/taaos"
SUPPORT_URL="https://github.com/tahasezer/taaos/issues"
BUG_REPORT_URL="https://github.com/tahasezer/taaos/issues"
LOGO=taaos
EOF

cat > "$ROOTFS/etc/hostname" <<EOF
taaos
EOF

cat > "$ROOTFS/etc/hosts" <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   taaos.local taaos
EOF

# Phase 3: Install Kernel and Modules
echo ""
echo "═══ Phase 3: Installing Kernel ═══"

cp taaos-build/boot/* "$ROOTFS/boot/"
cp -r taaos-build/modules/lib/modules/* "$ROOTFS/usr/lib/modules/"

# Phase 4: Create Bootloader Config
echo ""
echo "═══ Phase 4: Configuring Bootloader ═══"

mkdir -p "$ROOTFS/boot/grub"
cat > "$ROOTFS/boot/grub/grub.cfg" <<'EOF'
set timeout=5
set default=0

menuentry "TaaOS" {
    linux /boot/vmlinuz-taaos root=/dev/sda2 rw quiet splash
    initrd /boot/taaos-initramfs.img
}

menuentry "TaaOS (Recovery Mode)" {
    linux /boot/vmlinuz-taaos root=/dev/sda2 rw single
    initrd /boot/taaos-initramfs.img
}
EOF

# Phase 5: Create Squashfs
echo ""
echo "═══ Phase 5: Creating Filesystem Image ═══"

mksquashfs "$ROOTFS" "$BUILD_DIR/taaos-rootfs.squashfs" \
    -comp zstd -Xcompression-level 19 -b 1M

# Phase 6: Build ISO
echo ""
echo "═══ Phase 6: Building ISO Image ═══"

ISO_DIR="$BUILD_DIR/iso"
mkdir -p "$ISO_DIR"/{boot/grub,live}

# Copy kernel and initramfs
cp "$ROOTFS/boot/vmlinuz-taaos" "$ISO_DIR/boot/"
cp "$ROOTFS/boot/taaos-initramfs.img" "$ISO_DIR/boot/"
cp "$BUILD_DIR/taaos-rootfs.squashfs" "$ISO_DIR/live/filesystem.squashfs"

# Create ISO GRUB config
cat > "$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set timeout=10
set default=0

menuentry "TaaOS Live" {
    linux /boot/vmlinuz-taaos boot=live quiet splash
    initrd /boot/taaos-initramfs.img
}

menuentry "TaaOS Installer" {
    linux /boot/vmlinuz-taaos boot=live installer quiet splash
    initrd /boot/taaos-initramfs.img
}
EOF

# Create ISO
grub-mkrescue -o "$BUILD_DIR/taaos-1.0-x86_64.iso" "$ISO_DIR"

# Phase 7: Generate Checksums
echo ""
echo "═══ Phase 7: Generating Checksums ═══"

cd "$BUILD_DIR"
sha256sum taaos-1.0-x86_64.iso > SHA256SUMS
md5sum taaos-1.0-x86_64.iso > MD5SUMS

# Phase 8: Create Release Package
echo ""
echo "═══ Phase 8: Creating Release Package ═══"

tar -czf taaos-1.0-complete.tar.gz \
    taaos-1.0-x86_64.iso \
    SHA256SUMS \
    MD5SUMS \
    kernel/boot/config-taaos

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  BUILD COMPLETE!                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Build Artifacts:"
echo "   ISO: $BUILD_DIR/taaos-1.0-x86_64.iso"
echo "   Kernel: $BUILD_DIR/kernel/boot/vmlinuz-taaos"
echo "   RootFS: $BUILD_DIR/taaos-rootfs.squashfs"
echo "   Package: $BUILD_DIR/taaos-1.0-complete.tar.gz"
echo ""
echo "✓ TaaOS is ready for deployment!"
echo ""
