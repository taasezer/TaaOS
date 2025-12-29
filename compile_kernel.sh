#!/bin/bash
# =============================================================================
# TaaOS Custom Kernel Compilation
# =============================================================================
# Compiles the latest Linux kernel from Linus Torvalds' repo
# with TaaOS-specific optimizations (ECC, PREEMPT, SELinux)
# =============================================================================

set -euo pipefail

echo "=============================================="
echo "  TaaOS Custom Kernel Compilation"
echo "=============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_SRC_DIR="${SCRIPT_DIR}/kernel-build/linux"
KERNEL_REPO="https://github.com/torvalds/linux.git"
PACKAGES_CHROOT_DIR="${SCRIPT_DIR}/config/packages.chroot"
NPROC=$(nproc)

echo "[KERNEL] Script directory: ${SCRIPT_DIR}"
echo "[KERNEL] Kernel source: ${KERNEL_SRC_DIR}"
echo "[KERNEL] Packages output: ${PACKAGES_CHROOT_DIR}"
echo "[KERNEL] Using ${NPROC} CPU cores"

# =============================================================================
# STEP 1: Clone Kernel Source
# =============================================================================
echo ""
echo "=== STEP 1: Cloning Kernel Source ==="

if [[ ! -d "${KERNEL_SRC_DIR}" ]]; then
    echo "[KERNEL] Cloning Linux kernel from ${KERNEL_REPO}..."
    mkdir -p "$(dirname "${KERNEL_SRC_DIR}")"
    git clone --depth 1 "${KERNEL_REPO}" "${KERNEL_SRC_DIR}"
else
    echo "[KERNEL] Kernel source already exists, skipping clone"
fi

cd "${KERNEL_SRC_DIR}"
echo "[KERNEL] Working in: $(pwd)"

# =============================================================================
# STEP 2: Configure Kernel
# =============================================================================
echo ""
echo "=== STEP 2: Configuring Kernel ==="

# Clean previous builds
echo "[KERNEL] Cleaning previous build..."
make mrproper

# Start with default config
echo "[KERNEL] Generating default config..."
make defconfig

# Apply TaaOS-specific configurations
echo "[KERNEL] Applying TaaOS configurations..."

# ECC Memory Support (EDAC)
./scripts/config --enable CONFIG_EDAC
./scripts/config --enable CONFIG_EDAC_LEGACY_SYSFS

# PREEMPT for better responsiveness
./scripts/config --enable CONFIG_PREEMPT
./scripts/config --disable CONFIG_PREEMPT_VOLUNTARY

# SELinux Security
./scripts/config --enable CONFIG_SECURITY_SELINUX
./scripts/config --enable CONFIG_SECURITY_SELINUX_DEVELOP
./scripts/config --enable CONFIG_SECURITY_SELINUX_AVC_STATS

# Disable signature verification (required for custom kernel)
./scripts/config --disable CONFIG_SYSTEM_TRUSTED_KEYS
./scripts/config --disable CONFIG_SYSTEM_REVOCATION_KEYS
./scripts/config --disable CONFIG_MODULE_SIG_ALL
./scripts/config --disable CONFIG_MODULE_SIG_FORCE
./scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
./scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""

# Enable important kernel features
./scripts/config --enable CONFIG_BLK_DEV_INITRD
./scripts/config --enable CONFIG_RD_GZIP
./scripts/config --enable CONFIG_RD_BZIP2
./scripts/config --enable CONFIG_RD_LZMA
./scripts/config --enable CONFIG_RD_XZ
./scripts/config --enable CONFIG_RD_LZO
./scripts/config --enable CONFIG_RD_LZ4
./scripts/config --enable CONFIG_RD_ZSTD

# Virtualization support (for VirtualBox/QEMU)
./scripts/config --enable CONFIG_HYPERVISOR_GUEST
./scripts/config --enable CONFIG_PARAVIRT
./scripts/config --enable CONFIG_KVM_GUEST
./scripts/config --enable CONFIG_VIRTIO
./scripts/config --enable CONFIG_VIRTIO_PCI
./scripts/config --enable CONFIG_VIRTIO_BLK
./scripts/config --enable CONFIG_VIRTIO_NET

# Update config with all dependencies
echo "[KERNEL] Resolving config dependencies..."
make olddefconfig

echo "[KERNEL] Configuration complete"

# =============================================================================
# STEP 3: Compile Kernel
# =============================================================================
echo ""
echo "=== STEP 3: Compiling Kernel (this will take a while) ==="
echo "[KERNEL] Starting compilation with ${NPROC} parallel jobs..."

# Compile everything
make -j"${NPROC}" all

echo "[KERNEL] Compilation successful!"

# =============================================================================
# STEP 4: Create Debian Packages
# =============================================================================
echo ""
echo "=== STEP 4: Creating Debian Packages ==="

# Build .deb packages
make -j"${NPROC}" bindeb-pkg \
    LOCALVERSION="-taaos" \
    KDEB_PKGVERSION="1.0.0-taaos"

echo "[KERNEL] Debian packages created!"

# =============================================================================
# STEP 5: Move Packages to Config Directory
# =============================================================================
echo ""
echo "=== STEP 5: Moving Packages ==="

mkdir -p "${PACKAGES_CHROOT_DIR}"

# Move all generated .deb files
mv ../*.deb "${PACKAGES_CHROOT_DIR}/"

echo "[KERNEL] Packages moved to: ${PACKAGES_CHROOT_DIR}"
echo "[KERNEL] Package contents:"
ls -lh "${PACKAGES_CHROOT_DIR}/"

# =============================================================================
# COMPLETE
# =============================================================================
echo ""
echo "=============================================="
echo "  TaaOS Kernel Compilation - COMPLETE!"
echo "=============================================="
echo ""
echo "  Kernel packages are ready in:"
echo "  ${PACKAGES_CHROOT_DIR}"
echo ""