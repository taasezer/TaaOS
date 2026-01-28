#!/bin/bash
# =============================================================================
# TaaOS Master Build - SURGICAL ISOLATION MODE (Windows/Git Bash Fix)
# =============================================================================
set -e

# CRITICAL: Disable MSYS path conversion for docker commands
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

IMAGE_NAME="taaos-builder:torvalds"
CONTAINER_NAME="taaos_factory_$(date +%s)"
ISO_NAME="TaaOS"

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║         TaaOS Build - LINUS TORVALDS IS A GENIUS                      ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"

# Cleanup old containers
echo "[1/6] Cleaning up old containers..."
docker rm -f $(docker ps -a -q -f name=taaos_factory) 2>/dev/null || true

# Build Docker image
echo "[2/6] Building Docker image..."
docker build -t "$IMAGE_NAME" -f docker/Dockerfile docker/

# Start container
echo "[3/6] Starting isolated container..."
docker run -d --name "$CONTAINER_NAME" --privileged "$IMAGE_NAME" sleep infinity

# Create directories inside container
echo "[4/6] Surgical file injection..."
docker exec "$CONTAINER_NAME" mkdir -p /build/config/hooks/normal
docker exec "$CONTAINER_NAME" mkdir -p /build/config/package-lists
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.chroot
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.binary
docker exec "$CONTAINER_NAME" mkdir -p /build/config/packages.chroot

# Copy main scripts
echo "    Copying scripts..."
docker cp ./init_config.sh "$CONTAINER_NAME":/build/
docker cp ./compile_kernel.sh "$CONTAINER_NAME":/build/

# Copy package lists
echo "    Copying package lists..."
docker cp ./config/package-lists/desktop.list.chroot "$CONTAINER_NAME":/build/config/package-lists/
docker cp ./config/package-lists/engineering.list.chroot "$CONTAINER_NAME":/build/config/package-lists/
docker cp ./config/package-lists/themes.list.chroot "$CONTAINER_NAME":/build/config/package-lists/
[ -f ./config/package-lists/live.list.chroot ] && docker cp ./config/package-lists/live.list.chroot "$CONTAINER_NAME":/build/config/package-lists/ || true

# Copy hooks
echo "    Copying hooks..."
[ -f ./config/hooks/normal/00-kernel-setup.hook.chroot ] && docker cp ./config/hooks/normal/00-kernel-setup.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true
[ -f ./config/hooks/normal/01-frameworks.hook.chroot ] && docker cp ./config/hooks/normal/01-frameworks.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true
[ -f ./config/hooks/normal/02-ai-natural.hook.chroot ] && docker cp ./config/hooks/normal/02-ai-natural.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true
[ -f ./config/hooks/normal/03-security.hook.chroot ] && docker cp ./config/hooks/normal/03-security.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true
[ -f ./config/hooks/normal/04-cli.hook.chroot ] && docker cp ./config/hooks/normal/04-cli.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true
[ -f ./config/hooks/normal/99-user.hook.chroot ] && docker cp ./config/hooks/normal/99-user.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy bootloader config (EFI)
echo "    Copying bootloader config..."
docker exec "$CONTAINER_NAME" mkdir -p /build/config/bootloaders/grub-efi
docker exec "$CONTAINER_NAME" mkdir -p /build/config/bootloaders/grub-pc
docker exec "$CONTAINER_NAME" mkdir -p /build/config/hooks/live
docker exec "$CONTAINER_NAME" mkdir -p /build/config/hooks/normal
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.binary
[ -f ./config/bootloaders/grub-efi/grub.cfg ] && docker cp ./config/bootloaders/grub-efi/grub.cfg "$CONTAINER_NAME":/build/config/bootloaders/grub-efi/ || true
[ -f ./config/bootloaders/grub-pc/grub.cfg ] && docker cp ./config/bootloaders/grub-pc/grub.cfg "$CONTAINER_NAME":/build/config/bootloaders/grub-pc/ || true

# Copy EFI fix hook (CRITICAL for VM Boot)
echo "    Copying EFI fix hook..."
[ -f ./config/hooks/normal/09-efi-fix.hook.chroot ] && docker cp ./config/hooks/normal/09-efi-fix.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy live hooks (binary stage)
echo "    Copying live hooks..."
[ -f ./config/hooks/live/00-copy-kernel.hook.binary ] && docker cp ./config/hooks/live/00-copy-kernel.hook.binary "$CONTAINER_NAME":/build/config/hooks/live/ || true

# Copy UX branding hook
echo "    Copying UX branding hook..."
[ -f ./config/hooks/normal/05-ux-branding.hook.chroot ] && docker cp ./config/hooks/normal/05-ux-branding.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy performance/security hook
echo "    Copying performance/security hook..."
[ -f ./config/hooks/normal/06-perf-security.hook.chroot ] && docker cp ./config/hooks/normal/06-perf-security.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy devops hook
echo "    Copying devops hook..."
[ -f ./config/hooks/normal/07-devops-tools.hook.chroot ] && docker cp ./config/hooks/normal/07-devops-tools.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy core installer hook
echo "    Copying core installer hook..."
[ -f ./config/hooks/normal/08-core-installer.hook.chroot ] && docker cp ./config/hooks/normal/08-core-installer.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy OS configuration hook (CRITICAL for full OS)
echo "    Copying OS configuration hook..."
[ -f ./config/hooks/normal/10-os-config.hook.chroot ] && docker cp ./config/hooks/normal/10-os-config.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy Calamares installer hook (CRITICAL for graphical installation)
echo "    Copying Calamares installer hook..."
[ -f ./config/hooks/normal/11-calamares.hook.chroot ] && docker cp ./config/hooks/normal/11-calamares.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy Branding hook (Plymouth, XFCE theme, wallpaper)
echo "    Copying Branding hook..."
[ -f ./config/hooks/normal/12-branding.hook.chroot ] && docker cp ./config/hooks/normal/12-branding.hook.chroot "$CONTAINER_NAME":/build/config/hooks/normal/ || true

# Copy scripts directory (all subdirectories)
echo "    Copying scripts..."
docker exec "$CONTAINER_NAME" mkdir -p /build/scripts/ux /build/scripts/performance /build/scripts/security /build/scripts/devops /build/scripts/core
[ -d ./scripts/ux ] && docker cp ./scripts/ux/. "$CONTAINER_NAME":/build/scripts/ux/ || true
[ -d ./scripts/performance ] && docker cp ./scripts/performance/. "$CONTAINER_NAME":/build/scripts/performance/ || true
[ -d ./scripts/security ] && docker cp ./scripts/security/. "$CONTAINER_NAME":/build/scripts/security/ || true
[ -d ./scripts/devops ] && docker cp ./scripts/devops/. "$CONTAINER_NAME":/build/scripts/devops/ || true
[ -d ./scripts/core ] && docker cp ./scripts/core/. "$CONTAINER_NAME":/build/scripts/core/ || true

# Copy system configuration files (CRITICAL for full OS)
echo "    Copying system configuration files..."
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.chroot/usr/lib/taaos
[ -d ./config/includes.chroot/usr/lib/taaos ] && docker cp ./config/includes.chroot/usr/lib/taaos/. "$CONTAINER_NAME":/build/config/includes.chroot/usr/lib/taaos/ || true

# Copy systemd services
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.chroot/etc/systemd/system
[ -f ./config/includes.chroot/etc/systemd/system/taaos-first-boot.service ] && docker cp ./config/includes.chroot/etc/systemd/system/taaos-first-boot.service "$CONTAINER_NAME":/build/config/includes.chroot/etc/systemd/system/ || true

# Copy LightDM auto-login configuration (CRITICAL for live session)
echo "    Copying LightDM live session config..."
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.chroot/etc/lightdm/lightdm.conf.d
[ -f ./config/includes.chroot/etc/lightdm/lightdm.conf.d/50-taaos-live.conf ] && docker cp ./config/includes.chroot/etc/lightdm/lightdm.conf.d/50-taaos-live.conf "$CONTAINER_NAME":/build/config/includes.chroot/etc/lightdm/lightdm.conf.d/ || true

# Copy autostart entries
echo "    Copying autostart entries..."
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.chroot/etc/xdg/autostart
[ -f ./config/includes.chroot/etc/xdg/autostart/taaos-welcome.desktop ] && docker cp ./config/includes.chroot/etc/xdg/autostart/taaos-welcome.desktop "$CONTAINER_NAME":/build/config/includes.chroot/etc/xdg/autostart/ || true

# Copy desktop shortcuts
echo "    Copying desktop shortcuts..."
docker exec "$CONTAINER_NAME" mkdir -p /build/config/includes.chroot/etc/skel/Desktop
[ -f ./config/includes.chroot/etc/skel/Desktop/install-taaos.desktop ] && docker cp ./config/includes.chroot/etc/skel/Desktop/install-taaos.desktop "$CONTAINER_NAME":/build/config/includes.chroot/etc/skel/Desktop/ || true

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
    find . -type f \( -name "*.sh" -o -name "*.chroot" -o -name "*.binary" -o -name "*.list.*" \) -exec dos2unix {} \; 2>/dev/null || true

    
    chmod +x *.sh
    
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
    
    # Run live-build config
    echo "=== PHASE B: Live-Build Config ==="
    ./init_config.sh
    
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