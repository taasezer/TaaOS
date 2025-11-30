#!/bin/bash
#
# TaaOS ISO Builder
# Creates bootable ISO image with full TaaOS installation
#

set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TAAOS_ROOT="$(dirname "${SCRIPT_DIR}")"
ISO_DIR="${TAAOS_ROOT}/iso"
BUILD_DIR="${ISO_DIR}/build"
OUTPUT_DIR="${ISO_DIR}/output"
WORK_DIR="${BUILD_DIR}/work"
AIROOTFS="${WORK_DIR}/airootfs"

ISO_LABEL="TAAOS"
ISO_VERSION="${ISO_VERSION:-rolling}"
ISO_NAME="taaos-${ISO_VERSION}-x86_64.iso"

echo "========================================="
echo "  TaaOS ISO Builder"
echo "========================================="
echo ""
echo "Version: ${ISO_VERSION}"
echo "Output:  ${OUTPUT_DIR}/${ISO_NAME}"
echo ""

# Check dependencies
echo "[1/12] Checking dependencies..."
DEPS="mksquashfs xorriso grub-mkrescue"
for dep in $DEPS; do
    if ! command -v $dep &>/dev/null; then
        echo "ERROR: Required tool not found: $dep"
        echo "Install with: sudo pacman -S squashfs-tools libisoburn grub"
        exit 1
    fi
done

# Clean previous build
echo "[2/12] Cleaning previous build..."
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${AIROOTFS}"

# Create base filesystem
echo "[3/12] Creating base filesystem..."
mkdir -p "${AIROOTFS}"/{boot,dev,etc,home,mnt,opt,proc,root,run,srv,sys,tmp,usr,var}
mkdir -p "${AIROOTFS}/usr"/{bin,lib,lib64,sbin,share}
mkdir -p "${AIROOTFS}/var"/{cache,lib,log,spool,tmp}

# Install base system
echo "[4/12] Installing base system..."
# This would use taapac to install packages
# For this example, we'll copy essential files

# Copy kernel
if [ -f "${TAAOS_ROOT}/kernel/output/vmlinuz-"* ]; then
    KERNEL=$(ls ${TAAOS_ROOT}/kernel/output/vmlinuz-* | head -n1)
    cp "${KERNEL}" "${AIROOTFS}/boot/vmlinuz-taaos"
    echo "  Kernel: $(basename ${KERNEL})"
else
    echo "  WARNING: No kernel found, using system kernel"
    cp /boot/vmlinuz-linux "${AIROOTFS}/boot/vmlinuz-taaos" 2>/dev/null || true
fi

# Copy initramfs
if [ -f "${TAAOS_ROOT}/rootfs/output/initramfs-"* ]; then
    INITRAMFS=$(ls ${TAAOS_ROOT}/rootfs/output/initramfs-* | head -n1)
    cp "${INITRAMFS}" "${AIROOTFS}/boot/initramfs-taaos.img"
    echo "  Initramfs: $(basename ${INITRAMFS})"
fi

# Install TaaOS tools
echo "[5/12] Installing TaaOS tools..."
mkdir -p "${AIROOTFS}/usr/bin"
[ -f "${TAAOS_ROOT}/taapac/src/taapac" ] && \
    cp "${TAAOS_ROOT}/taapac/src/taapac" "${AIROOTFS}/usr/bin/"
[ -f "${TAAOS_ROOT}/taapac/src/taabuild" ] && \
    cp "${TAAOS_ROOT}/taapac/src/taabuild" "${AIROOTFS}/usr/bin/"
[ -f "${TAAOS_ROOT}/taatheme/engine/taatheme" ] && \
    cp "${TAAOS_ROOT}/taatheme/engine/taatheme" "${AIROOTFS}/usr/bin/"
[ -f "${TAAOS_ROOT}/security/guardian/taaos-guardian" ] && \
    cp "${TAAOS_ROOT}/security/guardian/taaos-guardian" "${AIROOTFS}/usr/bin/"

chmod +x "${AIROOTFS}/usr/bin"/* 2>/dev/null || true

# Install branding
echo "[6/12] Installing branding..."
mkdir -p "${AIROOTFS}/usr/share/taaos"
[ -d "${TAAOS_ROOT}/branding" ] && \
    cp -r "${TAAOS_ROOT}/branding"/* "${AIROOTFS}/usr/share/taaos/" 2>/dev/null || true

# Copy package list
mkdir -p "${AIROOTFS}/etc/taaos"
[ -f "${TAAOS_ROOT}/packages/default-packages.txt" ] && \
    cp "${TAAOS_ROOT}/packages/default-packages.txt" \
       "${AIROOTFS}/etc/taaos/packages.txt"

# Create TaaOS release file
echo "[7/12] Creating release info..."
cat > "${AIROOTFS}/etc/taaos/release" << EOF
NAME="TaaOS"
VERSION="${ISO_VERSION}"
ID=taaos
ID_LIKE=arch
PRETTY_NAME="TaaOS ${ISO_VERSION}"
ANSI_COLOR="0;31"  # Red (Rosso Corsa)
HOME_URL="https://taaos.org/"
DOCUMENTATION_URL="https://docs.taaos.org/"
SUPPORT_URL="https://forum.taaos.org/"
BUG_REPORT_URL="https://github.com/taaos/taaos/issues"
LOGO=taaos
EOF

# Create OS release
cp "${AIROOTFS}/etc/taaos/release" "${AIROOTFS}/etc/os-release"

# Create live environment configuration
echo "[8/12] Configuring live environment..."
mkdir -p "${AIROOTFS}/etc/systemd/system"

# Auto-login for live user
mkdir -p "${AIROOTFS}/etc/systemd/system/getty@tty1.service.d"
cat > "${AIROOTFS}/etc/systemd/system/getty@tty1.service.d/autologin.conf" << EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin taaos --noclear %I \$TERM
EOF

# Create live user
mkdir -p "${AIROOTFS}/etc/skel"
echo "taaos:x:1000:1000:TaaOS Live User:/home/taaos:/bin/zsh" >> "${AIROOTFS}/etc/passwd"
echo "taaos::14871::::::" >> "${AIROOTFS}/etc/shadow"

# Create installer script
echo "[9/12] Creating installer..."
cat > "${AIROOTFS}/usr/bin/taaos-install" << 'INSTALLER_EOF'
#!/bin/bash
#
# TaaOS Installer
# Simple installation script for TaaOS
#

clear
cat << "EOF"
 _____             ___  ____  
|_   _|_ _  __ _  / _ \/ ___| 
  | |/ _` |/ _` || | | \___ \ 
  | | (_| | (_| || |_| |___) |
  |_|\__,_|\__,_| \___/|____/ 
                              
TaaOS Installation
EOF

echo ""
echo "This will install TaaOS to your system."
echo "WARNING: This will format the selected disk!"
echo ""

# List disks
lsblk -d -o NAME,SIZE,TYPE | grep disk
echo ""
read -p "Enter disk to install to (e.g., sda, nvme0n1): " DISK

if [ -z "$DISK" ]; then
    echo "No disk selected. Exiting."
    exit 1
fi

DISK_PATH="/dev/${DISK}"

if [ ! -b "$DISK_PATH" ]; then
    echo "Error: Disk $DISK_PATH not found!"
    exit 1
fi

echo ""
echo "Installing to: $DISK_PATH"
read -p "Continue? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "Installing TaaOS..."
echo "This will take several minutes..."

# Partition disk (simple single partition setup)
parted -s "$DISK_PATH" mklabel gpt
parted -s "$DISK_PATH" mkpart ESP fat32 1MiB 512MiB
parted -s "$DISK_PATH" set 1 boot on
parted -s "$DISK_PATH" mkpart primary btrfs 512MiB 100%

# Format partitions
mkfs.vfat -F32 "${DISK_PATH}1"
mkfs.btrfs -f "${DISK_PATH}2"

# Mount and create subvolumes
mount "${DISK_PATH}2" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
umount /mnt

# Mount with options
mount -o compress=zstd:1,noatime,space_cache=v2,ssd,discard=async,subvol=@ "${DISK_PATH}2" /mnt
mkdir -p /mnt/{boot,home,var,.snapshots}
mount "${DISK_PATH}1" /mnt/boot
mount -o compress=zstd:3,noatime,space_cache=v2,ssd,discard=async,subvol=@home "${DISK_PATH}2" /mnt/home
mount -o compress=zstd:1,noatime,space_cache=v2,ssd,discard=async,subvol=@var "${DISK_PATH}2" /mnt/var
mount -o compress=zstd:1,noatime,space_cache=v2,ssd,discard=async,subvol=@snapshots "${DISK_PATH}2" /mnt/.snapshots

# Install base system
echo "Installing packages..."
# This would use taapac to install from package list
# For now, copy live system
cp -ax / /mnt/ 2>/dev/null || true

# Install bootloader
echo "Installing bootloader..."
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=TaaOS
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Set hostname
read -p "Enter hostname [taaos]: " HOSTNAME
HOSTNAME="${HOSTNAME:-taaos}"
echo "$HOSTNAME" > /mnt/etc/hostname

# Create user
read -p "Enter username: " USERNAME
arch-chroot /mnt useradd -m -G wheel -s /bin/zsh "$USERNAME"
echo "Set password for $USERNAME:"
arch-chroot /mnt passwd "$USERNAME"

echo ""
echo "Installation complete!"
echo "You can now reboot into your new TaaOS system."
read -p "Reboot now? (yes/NO): " REBOOT

if [ "$REBOOT" == "yes" ]; then
    reboot
fi
INSTALLER_EOF

chmod +x "${AIROOTFS}/usr/bin/taaos-install"

# Create squashfs filesystem
echo "[10/12] Creating squashfs filesystem..."
mksquashfs "${AIROOTFS}" "${WORK_DIR}/airootfs.sfs" \
    -comp zstd -Xcompression-level 19 -b 1M -quiet

# Prepare ISO structure
echo "[11/12] Preparing ISO structure..."
mkdir -p "${WORK_DIR}/iso/boot/grub"

# Copy kernel and initramfs to ISO
cp "${AIROOTFS}/boot/vmlinuz-taaos" "${WORK_DIR}/iso/boot/"
cp "${AIROOTFS}/boot/initramfs-taaos.img" "${WORK_DIR}/iso/boot/"
cp "${WORK_DIR}/airootfs.sfs" "${WORK_DIR}/iso/boot/"

# Create GRUB config
cat > "${WORK_DIR}/iso/boot/grub/grub.cfg" << EOF
set timeout=5
set default=0

menuentry "TaaOS ${ISO_VERSION} (x86_64)" {
    linux /boot/vmlinuz-taaos quiet splash
    initrd /boot/initramfs-taaos.img
}

menuentry "TaaOS ${ISO_VERSION} (x86_64, nomodeset)" {
    linux /boot/vmlinuz-taaos quiet splash nomodeset
    initrd /boot/initramfs-taaos.img
}
EOF

# Create ISO
echo "[12/12] Creating ISO image..."
grub-mkrescue -o "${OUTPUT_DIR}/${ISO_NAME}" \
    "${WORK_DIR}/iso" \
    -- -volid "${ISO_LABEL}" \
       -appid "TaaOS ${ISO_VERSION}" \
       -publisher "TaaOS Team" \
       -preparer "TaaOS ISO Builder" \
       -quiet

# Calculate checksums
cd "${OUTPUT_DIR}"
sha256sum "${ISO_NAME}" > "${ISO_NAME}.sha256"
md5sum "${ISO_NAME}" > "${ISO_NAME}.md5"

ISO_SIZE=$(du -h "${ISO_NAME}" | cut -f1)

echo ""
echo "========================================="
echo "  ISO Build Complete!"
echo "========================================="
echo ""
echo "ISO file:  ${OUTPUT_DIR}/${ISO_NAME}"
echo "Size:      ${ISO_SIZE}"
echo "SHA256:    $(cat ${ISO_NAME}.sha256 | cut -d' ' -f1)"
echo ""
echo "To test the ISO:"
echo "  qemu-system-x86_64 -m 2048 -cdrom ${OUTPUT_DIR}/${ISO_NAME}"
echo ""
echo "To write to USB:"
echo "  sudo dd if=${OUTPUT_DIR}/${ISO_NAME} of=/dev/sdX bs=4M status=progress"
echo ""
