#!/bin/bash
# =============================================================================
# TaaOS Custom Kernel Compilation
# =============================================================================
# Compiles the latest Linux kernel from Linus Torvalds' repo
# with TaaOS-specific optimizations (ECC, PREEMPT, SELinux)
# =============================================================================
# Phase 1 Hardening: Error handling, logging, retry logic
# =============================================================================

set -euo pipefail

# =============================================================================
# SOURCE COMMON LIBRARY IF AVAILABLE
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/scripts/lib/common.sh" ]]; then
    source "${SCRIPT_DIR}/scripts/lib/common.sh"
    enable_error_trap
elif [[ -f "/build/scripts/lib/common.sh" ]]; then
    source "/build/scripts/lib/common.sh"
    enable_error_trap
else
    # Fallback logging functions if common.sh not available
    log_info() { echo "[INFO] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_success() { echo "[SUCCESS] $*"; }
    log_phase() { echo ""; echo "=== $1 ==="; echo ""; }
fi

# =============================================================================
# BANNER
# =============================================================================
echo "=============================================="
echo "  TaaOS Custom Kernel Compilation"
echo "=============================================="

# =============================================================================
# CONFIGURATION
# =============================================================================
KERNEL_SRC_DIR="${SCRIPT_DIR}/kernel-build/linux"
KERNEL_REPO="https://github.com/torvalds/linux.git"
PACKAGES_CHROOT_DIR="${SCRIPT_DIR}/config/packages.chroot"
NPROC=$(nproc)
MAX_CLONE_RETRIES=3
CLONE_RETRY_DELAY=10

log_info "Script directory: ${SCRIPT_DIR}"
log_info "Kernel source: ${KERNEL_SRC_DIR}"
log_info "Packages output: ${PACKAGES_CHROOT_DIR}"
log_info "Using ${NPROC} CPU cores"

# =============================================================================
# STEP 1: Clone Kernel Source (with retry logic)
# =============================================================================
log_phase "STEP 1: CLONING KERNEL SOURCE"

if [[ ! -d "${KERNEL_SRC_DIR}" ]]; then
    log_info "Cloning Linux kernel from ${KERNEL_REPO}..."
    mkdir -p "$(dirname "${KERNEL_SRC_DIR}")"
    
    # Retry logic for network resilience
    clone_attempt=1
    clone_success=false
    
    while [[ $clone_attempt -le $MAX_CLONE_RETRIES ]]; do
        log_info "Clone attempt ${clone_attempt}/${MAX_CLONE_RETRIES}..."
        
        if git clone --depth 1 "${KERNEL_REPO}" "${KERNEL_SRC_DIR}"; then
            clone_success=true
            log_success "Kernel source cloned successfully"
            break
        fi
        
        if [[ $clone_attempt -lt $MAX_CLONE_RETRIES ]]; then
            log_warn "Clone failed, retrying in ${CLONE_RETRY_DELAY} seconds..."
            sleep "${CLONE_RETRY_DELAY}"
        fi
        
        ((clone_attempt++))
    done
    
    if [[ "$clone_success" != "true" ]]; then
        log_error "Failed to clone kernel source after ${MAX_CLONE_RETRIES} attempts"
        exit 3
    fi
else
    log_info "Kernel source already exists, skipping clone"
fi

cd "${KERNEL_SRC_DIR}"
log_info "Working in: $(pwd)"

# =============================================================================
# STEP 2: Configure Kernel
# =============================================================================
log_phase "STEP 2: CONFIGURING KERNEL"

# Clean previous builds
log_info "Cleaning previous build..."
make mrproper

# Start with default config
log_info "Generating default config..."
make defconfig

# Apply TaaOS-specific configurations
log_info "Applying TaaOS configurations..."

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

# =============================================================================
# Docker/Container Support (CRITICAL for TaaOS DevOps features)
# =============================================================================
log_info "Adding container/namespace support..."

# Namespaces (required for container isolation)
./scripts/config --enable CONFIG_NAMESPACES
./scripts/config --enable CONFIG_NET_NS
./scripts/config --enable CONFIG_PID_NS
./scripts/config --enable CONFIG_IPC_NS
./scripts/config --enable CONFIG_UTS_NS
./scripts/config --enable CONFIG_USER_NS

# Control Groups (required for resource limits)
./scripts/config --enable CONFIG_CGROUPS
./scripts/config --enable CONFIG_CGROUP_CPUACCT
./scripts/config --enable CONFIG_CGROUP_DEVICE
./scripts/config --enable CONFIG_CGROUP_FREEZER
./scripts/config --enable CONFIG_CGROUP_SCHED
./scripts/config --enable CONFIG_CPUSETS
./scripts/config --enable CONFIG_MEMCG
./scripts/config --enable CONFIG_CGROUP_PIDS
./scripts/config --enable CONFIG_CGROUP_BPF

# Container networking
./scripts/config --enable CONFIG_VETH
./scripts/config --enable CONFIG_BRIDGE
./scripts/config --enable CONFIG_BRIDGE_NETFILTER
./scripts/config --enable CONFIG_NETFILTER_XT_MATCH_CONNTRACK
./scripts/config --enable CONFIG_NF_NAT
./scripts/config --enable CONFIG_IP_NF_NAT
./scripts/config --enable CONFIG_IP_NF_TARGET_MASQUERADE

# =============================================================================
# Filesystem Support (CRITICAL for live-build and persistence)
# =============================================================================
log_info "Adding filesystem support..."

# OverlayFS (CRITICAL for Phase 3 persistence)
./scripts/config --enable CONFIG_OVERLAY_FS

# Squashfs (CRITICAL for live-build)
./scripts/config --enable CONFIG_SQUASHFS
./scripts/config --enable CONFIG_SQUASHFS_XZ
./scripts/config --enable CONFIG_SQUASHFS_ZSTD
./scripts/config --enable CONFIG_SQUASHFS_LZO
./scripts/config --enable CONFIG_SQUASHFS_LZ4

# Additional filesystems
./scripts/config --enable CONFIG_EXT4_FS
./scripts/config --enable CONFIG_BTRFS_FS
./scripts/config --enable CONFIG_XFS_FS
./scripts/config --enable CONFIG_FUSE_FS

# =============================================================================
# Storage and Block Devices (CRITICAL for System Boot)
# =============================================================================
log_info "Adding storage device support..."

# NVMe Support
./scripts/config --enable CONFIG_NVME_CORE
./scripts/config --enable CONFIG_BLK_DEV_NVME

# SATA / AHCI Support
./scripts/config --enable CONFIG_ATA
./scripts/config --enable CONFIG_SATA_AHCI
./scripts/config --enable CONFIG_SATA_MOBILE_LPM_POLICY

# Device Mapper (Required for LVM, LUKS, Thin-provisioning, Snapshots)
./scripts/config --enable CONFIG_MD
./scripts/config --enable CONFIG_BLK_DEV_MD
./scripts/config --enable CONFIG_BLK_DEV_DM
./scripts/config --enable CONFIG_DM_CRYPT
./scripts/config --enable CONFIG_DM_SNAPSHOT
./scripts/config --enable CONFIG_DM_THIN_PROVISIONING
./scripts/config --enable CONFIG_DM_CACHE
./scripts/config --enable CONFIG_DM_WRITECACHE

# USB and USB Storage (CRITICAL for Live USB Boot)
./scripts/config --enable CONFIG_USB
./scripts/config --enable CONFIG_USB_STORAGE
./scripts/config --enable CONFIG_USB_UAS
./scripts/config --enable CONFIG_USB_XHCI_HCD
./scripts/config --enable CONFIG_USB_EHCI_HCD

# Input Devices (HID, Keyboards, Mice)
./scripts/config --enable CONFIG_INPUT_KEYBOARD
./scripts/config --enable CONFIG_INPUT_MOUSE
./scripts/config --enable CONFIG_HID_GENERIC
./scripts/config --enable CONFIG_USB_HID

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
log_info "Resolving config dependencies..."
make olddefconfig

log_success "Kernel configuration complete"

# =============================================================================
# STEP 2.5: Preserve Kernel Config
# =============================================================================
log_info "Preserving kernel configuration..."
KERNEL_CONFIG_DIR="${SCRIPT_DIR}/config/kernel"
mkdir -p "${KERNEL_CONFIG_DIR}"
cp .config "${KERNEL_CONFIG_DIR}/taaos-kernel.config"
log_success "Config saved to: ${KERNEL_CONFIG_DIR}/taaos-kernel.config"

# =============================================================================
# STEP 3: Compile Kernel
# =============================================================================
log_phase "STEP 3: COMPILING KERNEL"
log_info "Starting compilation with ${NPROC} parallel jobs..."
log_warn "This will take a while (30-60 minutes)..."

# Compile everything
COMPILE_START=$SECONDS
make -j"${NPROC}" all
COMPILE_ELAPSED=$((SECONDS - COMPILE_START))

log_success "Compilation successful! (${COMPILE_ELAPSED} seconds)"

# =============================================================================
# STEP 4: Create Debian Packages
# =============================================================================
log_phase "STEP 4: CREATING DEBIAN PACKAGES"

# Get kernel version for package naming
KERNEL_VERSION=$(make kernelversion)
log_info "Kernel version: ${KERNEL_VERSION}"

# Build .deb packages
make -j"${NPROC}" bindeb-pkg \
    LOCALVERSION="-taaos" \
    KDEB_PKGVERSION="${KERNEL_VERSION}-taaos"

log_success "Debian packages created!"

# =============================================================================
# STEP 5: Move Packages to Config Directory
# =============================================================================
log_phase "STEP 5: MOVING PACKAGES"

mkdir -p "${PACKAGES_CHROOT_DIR}"

# Move all generated .deb files
mv ../*.deb "${PACKAGES_CHROOT_DIR}/"

log_info "Packages moved to: ${PACKAGES_CHROOT_DIR}"
log_info "Package contents:"
ls -lh "${PACKAGES_CHROOT_DIR}/"

# =============================================================================
# COMPLETE
# =============================================================================
log_phase "KERNEL COMPILATION COMPLETE"
log_success "Kernel version: ${KERNEL_VERSION}-taaos"
log_success "Packages ready in: ${PACKAGES_CHROOT_DIR}"
log_success "Config saved to: ${KERNEL_CONFIG_DIR}/taaos-kernel.config"