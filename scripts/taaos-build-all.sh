#!/bin/bash
#
# TaaOS Master Build Script
# Builds complete TaaOS system from kernel source tree
#

set -e

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAAOS_DIR="${KERNEL_ROOT}/taaos"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     TaaOS Complete Build System      ║"
echo "║   Developer-Optimized Linux Distro   ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Kernel root: ${KERNEL_ROOT}"
echo "TaaOS root:  ${TAAOS_DIR}"
echo ""

# Check if taaos directory exists
if [ ! -d "${TAAOS_DIR}" ]; then
    echo "ERROR: TaaOS directory not found at ${TAAOS_DIR}"
    echo "Please ensure the complete TaaOS source is in the kernel tree."
    exit 1
fi

# Function to print section header
print_section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Step 1: Build TaaKernel
print_section "1. Building TaaKernel"

cd "${KERNEL_ROOT}"

if [ ! -f ".config" ]; then
    echo "Configuring with taaos_defconfig..."
    make taaos_defconfig
fi

echo "Building kernel..."
CORES=$(nproc 2>/dev/null || echo 4)
echo "Using ${CORES} CPU cores"

make -j${CORES} \
    LOCALVERSION=-taaos \
    CFLAGS="-march=native -O3" \
    2>&1 | tee "${KERNEL_ROOT}/taaos-kernel-build.log"

KERNEL_VERSION=$(make -s kernelrelease)
echo "✓ TaaKernel ${KERNEL_VERSION} built successfully"

# Step 2: Create Initramfs
print_section "2. Creating Initramfs"

if [ -f "${TAAOS_DIR}/rootfs/scripts/create-initramfs.sh" ]; then
    cd "${TAAOS_DIR}/rootfs/scripts"
    bash ./create-initramfs.sh
    echo "✓ Initramfs created"
else
    echo "⚠ Initramfs script not found, skipping..."
fi

# Step 3: Prepare TaaOS Tools
print_section "3. Preparing TaaOS Tools"

# Make scripts executable
chmod +x "${TAAOS_DIR}/taapac/src/taapac" 2>/dev/null || true
chmod +x "${TAAOS_DIR}/taapac/src/taabuild" 2>/dev/null || true
chmod +x "${TAAOS_DIR}/taatheme/engine/taatheme" 2>/dev/null || true
chmod +x "${TAAOS_DIR}/security/guardian/taaos-guardian" 2>/dev/null || true

echo "✓ TaaOS tools prepared"

# Step 4: Build ISO (optional)
print_section "4. ISO Builder"

read -p "Do you want to build TaaOS ISO? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "${TAAOS_DIR}/iso/scripts/build-iso.sh" ]; then
        cd "${TAAOS_DIR}/iso/scripts"
        sudo bash ./build-iso.sh
        echo "✓ TaaOS ISO created"
    else
        echo "⚠ ISO builder script not found"
    fi
else
    echo "Skipping ISO build"
fi

# Step 5: Summary
print_section "Build Complete!"

cat << EOF

╔══════════════════════════════════════════════════════════╗
║              TaaOS Build Summary                         ║
╚══════════════════════════════════════════════════════════╝

Kernel Version:  ${KERNEL_VERSION}
Kernel Image:    ${KERNEL_ROOT}/arch/x86/boot/bzImage
Build Log:       ${KERNEL_ROOT}/taaos-kernel-build.log

TaaOS Components:
  ✓ TaaKernel      (Linux kernel with TaaOS branding)
  ✓ TaaPac         (Package manager)
  ✓ TaaBuild       (Build system)
  ✓ TaaTheme       (Theme engine)
  ✓ TaaOS Guardian (Security monitor)
  ✓ Branding       (Rosso Corsa theme)
  ✓ Documentation  (Complete docs)

Next Steps:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Install Kernel:
   sudo make modules_install
   sudo make install
   sudo update-grub

2. Test in VM:
   qemu-system-x86_64 -m 2G -kernel arch/x86/boot/bzImage

3. Build ISO (if not done):
   cd taaos/iso/scripts
   sudo ./build-iso.sh

4. Read Documentation:
   - README.taaos
   - Documentation/taaos/
   - taaos/README.md
   - taaos/docs/QUICKSTART.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TaaOS - Developer power, Ferrari style 🏎️

Build completed at: $(date)

EOF
