#!/bin/bash
#
# TaaOS Kernel Quick Build Script
# Integrated into Linux kernel source tree
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$(dirname "$(dirname "${SCRIPT_DIR}")")"

cd "${KERNEL_DIR}"

echo "======================================"
echo "  TaaOS Kernel Builder"
echo "======================================"
echo ""
echo "Kernel directory: ${KERNEL_DIR}"
echo ""

# Check if config exists
if [ ! -f ".config" ]; then
    echo "[1/5] Configuring kernel with TaaOS defaults..."
    make taaos_defconfig
else
    echo "[1/5] Using existing .config..."
fi

# Show version
echo "[2/5] Kernel version:"
make kernelrelease 2>/dev/null || echo "  (will be determined after config)"

# Clean
echo "[3/5] Cleaning previous build..."
make clean

# Build
echo "[4/5] Building TaaKernel..."
CORES=$(nproc 2>/dev/null || echo 4)
echo "  Using ${CORES} cores"

make -j${CORES} \
    LOCALVERSION=-taaos \
    CFLAGS="-march=native -O3"

# Create package
echo "[5/5] Creating kernel package..."
make -j${CORES} modules

KERNEL_VERSION=$(make -s kernelrelease)

echo ""
echo "======================================"
echo "  TaaKernel build complete!"
echo "======================================"
echo ""
echo "Kernel version: ${KERNEL_VERSION}"
echo "Kernel image:   arch/x86/boot/bzImage"
echo ""
echo "To install:"
echo "  sudo make modules_install"
echo "  sudo make install"
echo "  sudo update-grub"
echo ""
echo "Or create initramfs:"
echo "  cd taaos/rootfs/scripts"
echo "  ./create-initramfs.sh"
echo ""
