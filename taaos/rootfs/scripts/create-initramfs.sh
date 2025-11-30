#!/bin/bash
#
# TaaOS Initramfs Creation Script
# Creates a minimal, zstd-compressed initramfs for fast boot
#

set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TAAOS_ROOT="$(dirname "${SCRIPT_DIR}")"
BUILD_DIR="${BUILD_DIR:-${TAAOS_ROOT}/rootfs/build}"
OUTPUT_DIR="${OUTPUT_DIR:-${TAAOS_ROOT}/rootfs/output}"
KERNEL_VERSION="${KERNEL_VERSION:-$(uname -r)}"

echo "======================================"
echo "  TaaOS Initramfs Builder"
echo "======================================"
echo ""
echo "Build directory:   ${BUILD_DIR}"
echo "Output directory:  ${OUTPUT_DIR}"
echo "Kernel version:    ${KERNEL_VERSION}"
echo ""

# Create directories
mkdir -p "${BUILD_DIR}/initramfs"
mkdir -p "${OUTPUT_DIR}"

cd "${BUILD_DIR}/initramfs"

echo "[1/8] Creating directory structure..."
mkdir -p {bin,sbin,etc,proc,sys,run,usr/{bin,sbin},dev,tmp,mnt/root,lib,lib64}

echo "[2/8] Copying essential binaries..."
# Busybox provides most utilities in a single binary
if command -v busybox &>/dev/null; then
    cp /usr/bin/busybox bin/
    # Create symlinks for common commands
    cd bin
    for cmd in sh ash mount umount mkdir mknod cp mv rm cat echo ls; do
        ln -sf busybox $cmd
    done
    cd ..
else
    echo "WARNING: busybox not found, copying individual utilities..."
    # Fallback: copy individual binaries
    for binary in /bin/{sh,mount,umount,mkdir,cat,ls,cp,mv,rm}; do
        [ -e "$binary" ] && cp "$binary" bin/
    done
fi

echo "[3/8] Copying kernel modules..."
# Copy essential modules for boot
MODULES_DIR="/lib/modules/${KERNEL_VERSION}"
if [ -d "${MODULES_DIR}" ]; then
    mkdir -p "lib/modules/${KERNEL_VERSION}"
    
    # Essential modules for boot
    ESSENTIAL_MODULES=(
        "kernel/fs/btrfs"
        "kernel/fs/ext4"
        "kernel/drivers/ata"
        "kernel/drivers/scsi"
        "kernel/drivers/nvme"
        "kernel/drivers/block"
        "kernel/drivers/md"
    )
    
    for mod_path in "${ESSENTIAL_MODULES[@]}"; do
        if [ -d "${MODULES_DIR}/${mod_path}" ]; then
            mkdir -p "lib/modules/${KERNEL_VERSION}/${mod_path}"
            cp -r "${MODULES_DIR}/${mod_path}"/* \
                "lib/modules/${KERNEL_VERSION}/${mod_path}/" 2>/dev/null || true
        fi
    done
    
    # Copy module dependencies
    for dep_file in modules.{order,builtin,dep,dep.bin,alias,symbols}; do
        [ -f "${MODULES_DIR}/${dep_file}" ] && \
            cp "${MODULES_DIR}/${dep_file}" "lib/modules/${KERNEL_VERSION}/"
    done
else
    echo "WARNING: Kernel modules not found for version ${KERNEL_VERSION}"
fi

echo "[4/8] Copying libraries..."
# Copy essential libraries
copy_with_deps() {
    local binary=$1
    # Get library dependencies
    ldd "$binary" 2>/dev/null | grep -o '/[^ ]*' | while read lib; do
        if [ -f "$lib" ]; then
            local dest="lib/$(basename $lib)"
            [ -f "$dest" ] || cp "$lib" "$dest"
        fi
    done
}

# Copy libs for busybox/sh if they exist
[ -f bin/busybox ] && copy_with_deps /usr/bin/busybox
[ -f bin/sh ] && copy_with_deps /bin/sh

# Essential libraries (if not already copied)
for lib in /lib/x86_64-linux-gnu/{libc,libm,libdl,libpthread,ld-linux}*.so*; do
    [ -f "$lib" ] && cp "$lib" lib/ 2>/dev/null || true
done

echo "[5/8] Creating init script..."
cat > init << 'INIT_EOF'
#!/bin/sh
#
# TaaOS Initramfs Init
# Minimal init script for fast boot
#

# Mount essential filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t tmpfs tmpfs /run

# Print TaaOS boot message
echo ""
echo "======================================"
echo "       TaaOS Fast Boot Init"
echo "======================================"
echo ""

# Parse kernel command line
INIT=/sbin/init
ROOT=
ROOTFLAGS=
ROOTFSTYPE=auto

for param in $(cat /proc/cmdline); do
    case "${param}" in
        root=*)      ROOT="${param#root=}" ;;
        rootflags=*) ROOTFLAGS="${param#rootflags=}" ;;
        rootfstype=*) ROOTFSTYPE="${param#rootfstype=}" ;;
        init=*)      INIT="${param#init=}" ;;
    esac
done

# Detect root device if not specified
if [ -z "${ROOT}" ]; then
    echo "ERROR: No root device specified!"
    echo "Please specify root= on kernel command line"
    exec /bin/sh
fi

echo "Root device: ${ROOT}"
echo "Root FS type: ${ROOTFSTYPE}"

# Wait for root device (max 5 seconds)
WAIT_COUNT=0
while [ ! -e "${ROOT}" ] && [ ${WAIT_COUNT} -lt 50 ]; do
    sleep 0.1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ ! -e "${ROOT}" ]; then
    echo "ERROR: Root device ${ROOT} not found!"
    exec /bin/sh
fi

# Load filesystem modules
modprobe ${ROOTFSTYPE} 2>/dev/null || true

# Mount root filesystem
echo "Mounting root filesystem..."
MOUNT_OPTS=""
[ -n "${ROOTFLAGS}" ] && MOUNT_OPTS="-o ${ROOTFLAGS}"

if mount -t ${ROOTFSTYPE} ${MOUNT_OPTS} ${ROOT} /mnt/root; then
    echo "Root filesystem mounted successfully"
else
    echo "ERROR: Failed to mount root filesystem!"
    exec /bin/sh
fi

# Clean up
echo "Switching to real root..."
umount /proc
umount /sys
umount /dev
umount /run

# Switch to real root
exec switch_root /mnt/root ${INIT}
INIT_EOF

chmod +x init

echo "[6/8] Creating device nodes..."
# Create essential device nodes
mknod -m 600 dev/console c 5 1
mknod -m 666 dev/null c 1 3
mknod -m 666 dev/zero c 1 5
mknod -m 666 dev/tty c 5 0

echo "[7/8] Building initramfs archive..."
find . | cpio -H newc -o --quiet | \
    zstd -19 -T0 > "${OUTPUT_DIR}/initramfs-${KERNEL_VERSION}.img"

# Calculate size
SIZE=$(du -h "${OUTPUT_DIR}/initramfs-${KERNEL_VERSION}.img" | cut -f1)

echo "[8/8] Cleaning up..."
cd "${BUILD_DIR}"
rm -rf initramfs

echo ""
echo "======================================"
echo "  Initramfs created successfully!"
echo "======================================"
echo ""
echo "Output: ${OUTPUT_DIR}/initramfs-${KERNEL_VERSION}.img"
echo "Size:   ${SIZE}"
echo ""
echo "To install:"
echo "  sudo cp ${OUTPUT_DIR}/initramfs-${KERNEL_VERSION}.img /boot/"
echo "  sudo update-grub"
echo ""
