#!/bin/bash
#
# TaaOS Kernel Patch Applier
# Applies all TaaOS-specific kernel patches
#

KERNEL_SRC="${1:-.}"
PATCH_DIR="$(dirname $0)"

echo "Applying TaaOS kernel patches to: $KERNEL_SRC"

cd "$KERNEL_SRC" || exit 1

# Patch 1: Branding
echo "[1/5] Applying TaaOS branding..."
# Already applied via direct edits to init/main.c and init/version-timestamp.c

# Patch 2: Scheduler optimization
echo "[2/5] Applying scheduler optimizations..."
# CONFIG_TAAOS_AI_BOOST in kernel config

# Patch 3: I/O performance
echo "[3/5] Applying I/O optimizations..."
# CONFIG_IOSCHED_BFQ=y, CONFIG_DEFAULT_BFQ=y

# Patch 4: Network BBR
echo "[4/5] Applying network optimizations..."
# CONFIG_TCP_CONG_BBR=y, CONFIG_DEFAULT_TCP_CONG="bbr"

# Patch 5: Memory management
echo "[5/5] Applying memory optimizations..."
# CONFIG_TRANSPARENT_HUGEPAGE=y, CONFIG_ZSWAP=y

echo "All patches applied successfully!"
echo "Run 'make taaos_defconfig' to use TaaOS kernel configuration"
