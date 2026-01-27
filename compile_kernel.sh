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

# EFI Support (CRITICAL for VM/UEFI Boot)
./scripts/config --enable CONFIG_EFI
./scripts/config --enable CONFIG_EFI_STUB
./scripts/config --enable CONFIG_EFI_MIXED
./scripts/config --enable CONFIG_EFI_VARS
./scripts/config --enable CONFIG_EFIVAR_FS
./scripts/config --enable CONFIG_UEFI_CPER
./scripts/config --enable CONFIG_EFI_ESRT
./scripts/config --enable CONFIG_EFI_RUNTIME_MAP
./scripts/config --enable CONFIG_DMI
./scripts/config --enable CONFIG_DMI_SYSFS

# Boot Protocol Support
./scripts/config --enable CONFIG_ACPI
./scripts/config --enable CONFIG_ACPI_SYSTEM_POWER_STATES_SUPPORT
./scripts/config --enable CONFIG_X86
./scripts/config --enable CONFIG_X86_64
./scripts/config --enable CONFIG_64BIT

# Framebuffer Support (for VM boot)
./scripts/config --enable CONFIG_FB
./scripts/config --enable CONFIG_FB_SIMPLE
./scripts/config --enable CONFIG_FB_VESA
./scripts/config --enable CONFIG_FB_EFI
./scripts/config --enable CONFIG_FRAMEBUFFER_CONSOLE
./scripts/config --enable CONFIG_VT
./scripts/config --enable CONFIG_VT_CONSOLE
./scripts/config --enable CONFIG_HW_CONSOLE

# Graphics Support (Safe defaults for VMs)
./scripts/config --enable CONFIG_DRM
./scripts/config --enable CONFIG_DRM_BOCHS
./scripts/config --enable CONFIG_DRM_CIRRUS_QEMU
./scripts/config --enable CONFIG_DRM_VIRTIO_GPU
./scripts/config --enable CONFIG_DRM_VBOXVIDEO
./scripts/config --enable CONFIG_DRM_VMWGFX
./scripts/config --enable CONFIG_DRM_FBDEV_EMULATION
./scripts/config --enable CONFIG_DRM_KMS_FB_HELPER

# Disable strict EFI security (allows unsigned boot)
./scripts/config --disable CONFIG_EFI_SECURE_BOOT_BOOTLOADER_SIGNING
./scripts/config --disable CONFIG_LOCK_DOWN_KERNEL

# Virtualization support (for VirtualBox/QEMU)
./scripts/config --enable CONFIG_HYPERVISOR_GUEST
./scripts/config --enable CONFIG_PARAVIRT
./scripts/config --enable CONFIG_KVM_GUEST
./scripts/config --enable CONFIG_VIRTIO
./scripts/config --enable CONFIG_VIRTIO_PCI
./scripts/config --enable CONFIG_VIRTIO_BLK
./scripts/config --enable CONFIG_VIRTIO_NET
./scripts/config --enable CONFIG_VIRTIO_CONSOLE
./scripts/config --enable CONFIG_VIRTIO_INPUT
./scripts/config --enable CONFIG_9P_FS
./scripts/config --enable CONFIG_9P_FS_POSIX_ACL
./scripts/config --enable CONFIG_NET_9P
./scripts/config --enable CONFIG_NET_9P_VIRTIO

# Network boot support (for PXE/Netboot)
./scripts/config --enable CONFIG_NET
./scripts/config --enable CONFIG_INET
./scripts/config --enable CONFIG_PACKET
./scripts/config --enable CONFIG_UNIX
./scripts/config --enable CONFIG_CFG80211
./scripts/config --enable CONFIG_CFG80211_WEXT
./scripts/config --enable CONFIG_MAC80211

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