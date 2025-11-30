#!/bin/bash
#
# TaaOS Complete Build Script
# Master build script that compiles everything from kernel to userspace
#

set -e

TAAOS_ROOT="$(pwd)"
BUILD_DIR="$TAAOS_ROOT/build"
INSTALL_DIR="$TAAOS_ROOT/install"

echo "========================================="
echo "   TaaOS Complete Build System"
echo "   Building the Future of Linux"
echo "========================================="
echo ""

# Step 1: Build Kernel
echo "[1/6] Building TaaOS Kernel..."
cd "$TAAOS_ROOT"
make -j$(nproc) LOCALVERSION=-taaos
make modules_install INSTALL_MOD_PATH="$INSTALL_DIR"
make install INSTALL_PATH="$INSTALL_DIR/boot"

# Step 2: Build TaaOS Components
echo "[2/6] Building TaaOS System Components..."
cd "$TAAOS_ROOT/taaos"
make -f "$TAAOS_ROOT/Makefile" install DESTDIR="$INSTALL_DIR"

# Step 3: Build Initramfs
echo "[3/6] Creating Initramfs..."
"$TAAOS_ROOT/taaos/rootfs/scripts/create-initramfs.sh"

# Step 4: Build ISO
echo "[4/6] Building ISO Image..."
"$TAAOS_ROOT/taaos/iso/scripts/build-iso.sh"

# Step 5: Package Everything
echo "[5/6] Creating Distribution Packages..."
cd "$BUILD_DIR"
tar -czf taaos-kernel-$(uname -r).tar.gz -C "$INSTALL_DIR" boot lib
tar -czf taaos-system-1.0.tar.gz -C "$INSTALL_DIR" usr etc

# Step 6: Generate Checksums
echo "[6/6] Generating Checksums..."
cd "$BUILD_DIR"
sha256sum *.tar.gz *.iso > SHA256SUMS

echo ""
echo "========================================="
echo "   Build Complete!"
echo "========================================="
echo "Kernel: $INSTALL_DIR/boot/vmlinuz-*-taaos"
echo "ISO: $BUILD_DIR/taaos-*.iso"
echo "Packages: $BUILD_DIR/*.tar.gz"
echo ""
echo "TaaOS is ready for deployment!"
