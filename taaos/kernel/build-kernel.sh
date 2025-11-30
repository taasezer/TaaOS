#!/bin/bash
#
# TaaKernel Build Script
# Builds the TaaOS optimized Linux kernel
#

set -e

KERNEL_SOURCE="${KERNEL_SOURCE:-/c/Users/tahas/OneDrive/Desktop/TaaOS}"
TAAOS_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
CONFIG_FILE="${TAAOS_ROOT}/kernel/configs/taakernel.config"
PATCH_DIR="${TAAOS_ROOT}/kernel/patches"
BUILD_DIR="${TAAOS_ROOT}/kernel/build"
OUTPUT_DIR="${TAAOS_ROOT}/kernel/output"

echo "======================================"
echo "  TaaOS Kernel Build System"
echo "======================================"
echo ""
echo "Kernel source: ${KERNEL_SOURCE}"
echo "Config file:   ${CONFIG_FILE}"
echo "Patch dir:     ${PATCH_DIR}"
echo "Build dir:     ${BUILD_DIR}"
echo "Output dir:    ${OUTPUT_DIR}"
echo ""

# Create output directories
mkdir -p "${BUILD_DIR}"
mkdir -p "${OUTPUT_DIR}"

cd "${KERNEL_SOURCE}"

# Clean previous build
echo "[1/7] Cleaning previous build..."
make mrproper

# Apply TaaOS patches
if [ -d "${PATCH_DIR}" ] && [ "$(ls -A ${PATCH_DIR}/*.patch 2>/dev/null)" ]; then
    echo "[2/7] Applying TaaOS kernel patches..."
    for patch in "${PATCH_DIR}"/*.patch; do
        echo "  Applying: $(basename ${patch})"
        patch -p1 < "${patch}"
    done
else
    echo "[2/7] No patches to apply"
fi

# Configure kernel
echo "[3/7] Configuring TaaKernel..."
if [ -f "${CONFIG_FILE}" ]; then
    # Use TaaOS custom config as base
    cp "${CONFIG_FILE}" .config
    # Update config for current kernel version
    make olddefconfig
else
    echo "ERROR: TaaKernel config not found at ${CONFIG_FILE}"
    exit 1
fi

# Enable additional optimizations
echo "[4/7] Applying build-time optimizations..."
scripts/config --set-str LOCALVERSION "-taaos"
scripts/config --enable LOCALVERSION_AUTO

# Compiler optimizations (-O3, LTO if available)
scripts/config --disable CC_OPTIMIZE_FOR_SIZE
scripts/config --enable CC_OPTIMIZE_FOR_PERFORMANCE_O3 2>/dev/null || true
scripts/config --enable LTO_CLANG_THIN 2>/dev/null || true

# Build kernel
echo "[5/7] Building TaaKernel..."
CORES=$(nproc)
echo "  Using ${CORES} cores"

make -j${CORES} \
    CC=gcc \
    CFLAGS="-march=native -O3" \
    all

# Install modules to temporary directory
echo "[6/7] Installing kernel modules..."
make INSTALL_MOD_PATH="${BUILD_DIR}/modules" modules_install

# Copy kernel and config
echo "[7/7] Copying kernel image and config..."
KERNEL_VERSION=$(make kernelrelease)
echo "  Kernel version: ${KERNEL_VERSION}"

cp arch/x86/boot/bzImage "${OUTPUT_DIR}/vmlinuz-${KERNEL_VERSION}"
cp .config "${OUTPUT_DIR}/config-${KERNEL_VERSION}"
cp System.map "${OUTPUT_DIR}/System.map-${KERNEL_VERSION}"

# Create kernel package tarball
cd "${BUILD_DIR}"
echo "Creating kernel package..."
tar czf "${OUTPUT_DIR}/taakernel-${KERNEL_VERSION}.tar.gz" modules/

echo ""
echo "======================================"
echo "  TaaKernel build complete!"
echo "======================================"
echo ""
echo "Kernel image: ${OUTPUT_DIR}/vmlinuz-${KERNEL_VERSION}"
echo "Modules:      ${OUTPUT_DIR}/taakernel-${KERNEL_VERSION}.tar.gz"
echo "Config:       ${OUTPUT_DIR}/config-${KERNEL_VERSION}"
echo "System.map:   ${OUTPUT_DIR}/System.map-${KERNEL_VERSION}"
echo ""
echo "To install:"
echo "  sudo cp ${OUTPUT_DIR}/vmlinuz-${KERNEL_VERSION} /boot/"
echo "  sudo tar xzf ${OUTPUT_DIR}/taakernel-${KERNEL_VERSION}.tar.gz -C /"
echo "  sudo mkinitcpio -k ${KERNEL_VERSION} -g /boot/initramfs-${KERNEL_VERSION}.img"
echo ""
