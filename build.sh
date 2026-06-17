#!/bin/bash
# =============================================================================
# TaaOS Master Build - SURGICAL ISOLATION MODE (Windows/Git Bash Fix)
# =============================================================================
# Phase 1 Hardening: Error handling, logging, pre-flight checks
# =============================================================================
set -euo pipefail

# CRITICAL: Disable MSYS path conversion for docker commands
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# =============================================================================
# SOURCE COMMON LIBRARY IF AVAILABLE
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/scripts/lib/common.sh" ]]; then
    source "${SCRIPT_DIR}/scripts/lib/common.sh"
    init_logging
    enable_error_trap
    LOGGING_ENABLED=true
else
    LOGGING_ENABLED=false
    log_info() { echo "[INFO] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_success() { echo "[SUCCESS] $*"; }
    log_phase() { echo ""; echo "=== $1 ==="; echo ""; }
fi

# =============================================================================
# CONFIGURATION
# =============================================================================
IMAGE_NAME="taaos-builder:torvalds"
CONTAINER_NAME="taaos_factory_$(date +%s)"
ISO_NAME="TaaOS"

# =============================================================================
# CLEANUP HANDLER (Called on error or exit)
# =============================================================================
taaos_cleanup() {
    if [[ -n "${CONTAINER_NAME:-}" ]]; then
        log_warn "Cleaning up container: ${CONTAINER_NAME}"
        docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
    fi
}

# Register cleanup on script exit (success or failure)
trap taaos_cleanup EXIT

# =============================================================================
# BANNER
# =============================================================================
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║         TaaOS Build - LINUS TORVALDS IS A GENIUS                      ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
log_phase "PRE-FLIGHT CHECKS"

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed!"
    exit 2
fi

if ! docker info &> /dev/null 2>&1; then
    log_error "Docker daemon is not running!"
    exit 2
fi
log_success "Docker is available"

# Check disk space (warn only, don't block)
if command -v df &> /dev/null; then
    available_gb=$(df -BG . 2>/dev/null | awk 'NR==2 {gsub(/G/,""); print $4}' || echo "0")
    if [[ "${available_gb:-0}" -lt 20 ]]; then
        log_warn "Low disk space: ${available_gb}GB available (20GB recommended)"
    else
        log_success "Disk space OK: ${available_gb}GB available"
    fi
fi

log_success "Pre-flight checks passed"

# =============================================================================
# PHASE 1: CLEANUP
# =============================================================================
log_phase "PHASE 1/6: CLEANUP"
log_info "Cleaning up old containers..."
docker rm -f $(docker ps -a -q -f name=taaos_factory) 2>/dev/null || true

# =============================================================================
# PHASE 2: BUILD DOCKER IMAGE
# =============================================================================
log_phase "PHASE 2/6: BUILD DOCKER IMAGE"
log_info "Building Docker image: ${IMAGE_NAME}..."
docker build -t "$IMAGE_NAME" -f docker/Dockerfile docker/
log_success "Docker image built successfully"

# =============================================================================
# PHASE 3: START CONTAINER
# =============================================================================
log_phase "PHASE 3/6: START ISOLATED CONTAINER"
log_info "Starting container: ${CONTAINER_NAME}..."
# NOTE: --privileged is required for live-build mknod and loop device operations
docker run -d --name "$CONTAINER_NAME" --privileged "$IMAGE_NAME" sleep infinity
log_success "Container started successfully"

# =============================================================================
# PHASE 4: SURGICAL FILE INJECTION
# =============================================================================
log_phase "PHASE 4/6: SURGICAL FILE INJECTION"
log_info "Creating directory structure inside container..."
docker exec "$CONTAINER_NAME" mkdir -p /build/config/hooks/live
docker exec "$CONTAINER_NAME" mkdir -p /build/config/package-lists
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.chroot
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.binary
docker exec "$CONTAINER_NAME" mkdir -p /build/config/packages.chroot

# Copy main scripts
echo "    Copying scripts..."
docker cp ./init_config.sh "$CONTAINER_NAME":/build/
docker cp ./compile_kernel.sh "$CONTAINER_NAME":/build/

# Copy package lists (ALL .list.chroot files)
echo "    Copying package lists..."
for listfile in ./config/package-lists/*.list.chroot; do
    if [ -f "$listfile" ]; then
        docker cp "$listfile" "$CONTAINER_NAME":/build/config/package-lists/
        echo "      ✓ $(basename "$listfile")"
    fi
done

# Copy hooks (ALL hooks automatically)
echo "    Copying hooks..."
for hookfile in ./config/hooks/live/*.hook.chroot ./config/hooks/live/*.hook.binary; do
    if [ -f "$hookfile" ]; then
        docker cp "$hookfile" "$CONTAINER_NAME":/build/config/hooks/live/
        echo "      ✓ $(basename "$hookfile")"
    fi
done

# Copy bootloader config (EFI + Legacy BIOS)
echo "    Copying bootloader config..."
docker exec "$CONTAINER_NAME" mkdir -p /build/config/bootloaders/grub-efi
docker exec "$CONTAINER_NAME" mkdir -p /build/config/bootloaders/grub-pc
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.binary
[ -f ./config/bootloaders/grub-efi/grub.cfg ] && docker cp ./config/bootloaders/grub-efi/grub.cfg "$CONTAINER_NAME":/build/config/bootloaders/grub-efi/ || true
[ -f ./config/bootloaders/grub-pc/grub.cfg ] && docker cp ./config/bootloaders/grub-pc/grub.cfg "$CONTAINER_NAME":/build/config/bootloaders/grub-pc/ || true

# Copy scripts directory (all subdirectories)
echo "    Copying scripts..."
docker exec "$CONTAINER_NAME" mkdir -p /build/scripts/ux /build/scripts/performance /build/scripts/security /build/scripts/devops /build/scripts/core /build/scripts/system /build/scripts/lib
[ -d ./scripts/ux ] && docker cp ./scripts/ux/. "$CONTAINER_NAME":/build/scripts/ux/ || true
[ -d ./scripts/performance ] && docker cp ./scripts/performance/. "$CONTAINER_NAME":/build/scripts/performance/ || true
[ -d ./scripts/security ] && docker cp ./scripts/security/. "$CONTAINER_NAME":/build/scripts/security/ || true
[ -d ./scripts/devops ] && docker cp ./scripts/devops/. "$CONTAINER_NAME":/build/scripts/devops/ || true
[ -d ./scripts/core ] && docker cp ./scripts/core/. "$CONTAINER_NAME":/build/scripts/core/ || true
[ -d ./scripts/system ] && docker cp ./scripts/system/. "$CONTAINER_NAME":/build/scripts/system/ || true
[ -d ./scripts/lib ] && docker cp ./scripts/lib/. "$CONTAINER_NAME":/build/scripts/lib/ || true

# Copy ENTIRE includes.chroot directory recursively (CRITICAL — all 40+ files)
echo "    Copying includes.chroot (full recursive)..."
if [ -d ./config/includes.chroot ]; then
    docker cp ./config/includes.chroot/. "$CONTAINER_NAME":/build/config/includes.chroot/
    echo "    ✓ includes.chroot copied successfully"
else
    echo "    ⚠ includes.chroot directory not found!"
fi

# Copy assets directory
echo "    Copying assets..."
docker exec "$CONTAINER_NAME" mkdir -p /build/assets
[ -d ./assets ] && docker cp ./assets/. "$CONTAINER_NAME":/build/assets/ 2>/dev/null || true

echo "    Files copied successfully!"

# Execute Build
echo "[5/6] Executing build inside container..."
docker exec -w /build "$CONTAINER_NAME" bash -c '
    set -e
    
    # Convert Windows CRLF to Unix LF
    echo "Converting CRLF to LF..."
    find . -type f \( -name "*.sh" -o -name "*.chroot" -o -name "*.binary" -o -name "*.list.*" -o -name "*.conf" -o -name "*.cfg" -o -name "*.py" -o -name "*.desktop" -o -name "*.service" -o -name "*.timer" \) -exec dos2unix {} \; 2>/dev/null || echo "[WARN] dos2unix conversion had issues for some source files (continuing)"
    # CRITICAL: Convert ALL files in includes.chroot (many have no extension)
    find config/includes.chroot -type f -exec dos2unix {} \; 2>/dev/null || echo "[WARN] dos2unix conversion had issues for includes.chroot files (continuing)"
    # Convert scripts directory
    find scripts -type f -exec dos2unix {} \; 2>/dev/null || echo "[WARN] dos2unix conversion had issues for scripts files (continuing)"
    
    # CRITICAL FIX: Inject scripts into chroot so hooks can access them!
    echo "Injecting scripts and assets into chroot for hooks to access..."
    mkdir -p config/includes.chroot/opt/taaos/scripts
    cp -r scripts/* config/includes.chroot/opt/taaos/scripts/ 2>/dev/null || true
    mkdir -p config/includes.chroot/opt/taaos/assets
    cp -r assets/* config/includes.chroot/opt/taaos/assets/ 2>/dev/null || true

    
    chmod +x *.sh
    
    # CRITICAL FIX: Ensure ALL hooks are executable! live-build drops hooks silently if they lack +x bit
    echo "Ensuring all hooks are executable..."
    find config/hooks -type f -exec chmod +x {} \; 2>/dev/null || true
    # Ensure ALL scripts in includes.chroot are executable
    find config/includes.chroot/usr/bin -type f -exec chmod +x {} \; 2>/dev/null || true
    find config/includes.chroot/usr/local/bin -type f -exec chmod +x {} \; 2>/dev/null || true
    find config/includes.chroot/usr/lib/taaos -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find config/includes.chroot/opt/taaos/scripts -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    # Verify files
    echo "=== Files in /build ==="
    ls -la
    echo "=== Package lists ==="
    ls -la config/package-lists/ || echo "No package lists!"
    
    # Run kernel compilation (ENABLED)
    echo "=== PHASE A: Kernel Compilation ==="
    ./compile_kernel.sh
    
    # Verify Kernel Packages
    echo "=== Verifying Kernel Packages ==="
    ls -lh config/packages.chroot/
    
    # Ensure packages are accessible
    chmod -R 777 config/packages.chroot 2>/dev/null || true
    
    # CRITICAL FIX: Force inject kernel into chroot because live-build might ignore them due to --linux-packages "none"
    echo "=== Injecting Kernel Packages into Chroot ==="
    mkdir -p config/includes.chroot/root/taaos-kernel
    cp config/packages.chroot/*.deb config/includes.chroot/root/taaos-kernel/ 2>/dev/null || true
    
    # Run live-build config
    echo "=== PHASE B: Live-Build Config ==="
    
    # CRITICAL: Backup custom files BEFORE lb config — it can reset config/ directory
    echo "    Backing up custom package-lists and hooks before lb config..."
    mkdir -p /tmp/taaos-backup/package-lists
    mkdir -p /tmp/taaos-backup/hooks
    cp -a config/package-lists/. /tmp/taaos-backup/package-lists/ 2>/dev/null || true
    cp -a config/hooks/live/. /tmp/taaos-backup/hooks/ 2>/dev/null || true
    
    ./init_config.sh
    
    # CRITICAL: Restore custom files AFTER lb config — in case lb config wiped them
    echo "    Restoring custom package-lists and hooks after lb config..."
    mkdir -p config/package-lists config/hooks/live
    cp -a /tmp/taaos-backup/package-lists/. config/package-lists/ 2>/dev/null || true
    cp -a /tmp/taaos-backup/hooks/. config/hooks/live/ 2>/dev/null || true
    # Re-ensure all hooks are executable after restore
    find config/hooks -type f -exec chmod +x {} \; 2>/dev/null || true
    echo "    === Final package lists ==="
    ls -la config/package-lists/
    echo "    === Final hooks ==="
    ls -la config/hooks/live/
    
    # Build ISO
    echo "=== PHASE C: Building ISO ==="
    lb build
'

BUILD_RESULT=$?

# Retrieve ISO
echo "[6/6] Retrieving ISO..."
if [ $BUILD_RESULT -eq 0 ]; then
    docker cp "$CONTAINER_NAME":/build/"$ISO_NAME"-amd64.hybrid.iso ./"$ISO_NAME".iso 2>/dev/null || \
    docker cp "$CONTAINER_NAME":/build/"$ISO_NAME".iso ./"$ISO_NAME".iso 2>/dev/null || \
    docker cp "$CONTAINER_NAME":/build/live-image-amd64.hybrid.iso ./"$ISO_NAME".iso 2>/dev/null || true
    
    docker rm -f "$CONTAINER_NAME"
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                    SUCCESS! ISO is ready.                             ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    ls -lh ./"$ISO_NAME".iso 2>/dev/null || echo "Check current directory for ISO"
else
    echo ""
    echo "BUILD FAILED! Container kept for debugging: $CONTAINER_NAME"
    echo "Debug: docker exec -it $CONTAINER_NAME bash"
    exit 1
fi