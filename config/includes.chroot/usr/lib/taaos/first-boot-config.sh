#!/bin/bash
# =============================================================================
# TaaOS First Boot Configuration
# =============================================================================
# Runs on first boot to configure the system as a full operating system
# =============================================================================

set -e

LOGFILE="/var/log/taaos-first-boot.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=============================================="
echo "[TaaOS] First Boot Configuration"
echo "=============================================="
echo "Date: $(date)"
echo ""

# =============================================================================
# SECTION 1: HARDWARE DETECTION
# =============================================================================
echo "[FIRST-BOOT] Detecting hardware..."

# CPU
CPU_MODEL=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
echo "  CPU: $CPU_MODEL"

# Memory
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
echo "  Memory: $MEM_TOTAL"

# Storage
DISK_INFO=$(lsblk -d -o NAME,SIZE,MODEL | grep -E "^sd|^nvme" | head -1)
echo "  Primary Storage: $DISK_INFO"

# Graphics
GPU_INFO=$(lspci | grep -i vga | head -1 | cut -d: -f3 | sed 's/^[ \t]*//')
if [ -z "$GPU_INFO" ]; then
    GPU_INFO=$(lspci | grep -i "3d controller" | head -1 | cut -d: -f3 | sed 's/^[ \t]*//')
fi
echo "  GPU: ${GPU_INFO:-Unknown}"

# =============================================================================
# SECTION 2: NETWORK CONFIGURATION
# =============================================================================
echo ""
echo "[FIRST-BOOT] Configuring network..."

# Enable NetworkManager
systemctl enable NetworkManager.service
systemctl start NetworkManager.service

# Configure hostname
if [ -f /etc/hostname ]; then
    HOSTNAME=$(cat /etc/hostname)
    hostnamectl set-hostname "$HOSTNAME"
    echo "  Hostname set to: $HOSTNAME"
fi

# Update /etc/hosts
if ! grep -q "127.0.1.1" /etc/hosts; then
    echo "127.0.1.1   $(hostname).localdomain $(hostname)" >> /etc/hosts
fi

# =============================================================================
# SECTION 3: SYSTEM SERVICES
# =============================================================================
echo ""
echo "[FIRST-BOOT] Enabling system services..."

# Core services
SERVICES=(
    "cron"
    "systemd-journald"
    "bluetooth"
    "cups"
    "thermald"
    "fstrim"
    "logrotate"
)

for service in "${SERVICES[@]}"; do
    if systemctl enable "$service" 2>/dev/null; then
        echo "  ✓ Enabled: $service"
    else
        echo "  ✗ Failed: $service (may not be installed)"
    fi
done

# =============================================================================
# SECTION 4: HARDWARE MONITORING
# =============================================================================
echo ""
echo "[FIRST-BOOT] Configuring hardware monitoring..."

# Load kernel modules
MODULES=(
    "coretemp"
    "nct6775"
    "it87"
    "edac_core"
    "kvm"
    "kvm_intel"
    "kvm_amd"
)

for module in "${MODULES[@]}"; do
    if modprobe "$module" 2>/dev/null; then
        echo "  ✓ Loaded: $module"
        # Add to /etc/modules if not present
        if ! grep -q "^$module$" /etc/modules; then
            echo "$module" >> /etc/modules
        fi
    else
        echo "  ✗ Failed: $module"
    fi
done

# Enable RAS daemon for ECC memory
if systemctl enable rasdaemon 2>/dev/null; then
    systemctl start rasdaemon 2>/dev/null || true
    echo "  ✓ Enabled: rasdaemon (ECC monitoring)"
fi

# Update sensors database
if command -v sensors-detect >/dev/null 2>&1; then
    echo "# TaaOS sensors configuration" > /etc/sensors3.conf
    sensors-detect --auto 2>/dev/null || true
fi

# =============================================================================
# SECTION 5: AUDIO CONFIGURATION
# =============================================================================
echo ""
echo "[FIRST-BOOT] Configuring audio..."

# Detect audio devices
AUDIO_CARDS=$(aplay -l 2>/dev/null | grep "card" | wc -l)
echo "  Audio cards detected: $AUDIO_CARDS"

if [ "$AUDIO_CARDS" -gt 0 ]; then
    # Configure PulseAudio
    if [ -d /etc/pulse ]; then
        echo "  Configuring PulseAudio..."
        # Set default sample rate
        if ! grep -q "default-sample-rate" /etc/pulse/daemon.conf 2>/dev/null; then
            echo "default-sample-rate = 48000" >> /etc/pulse/daemon.conf
        fi
    fi
    
    # Configure ALSA
    if [ -f /etc/asound.conf ]; then
        echo "  ALSA configuration exists"
    else
        # Create default ALSA config
        cat > /etc/asound.conf << 'EOF'
# Default ALSA configuration for TaaOS
pcm.!default {
    type hw
    card 0
}
ctl.!default {
    type hw
    card 0
}
EOF
    fi
fi

# =============================================================================
# SECTION 6: GRAPHICS CONFIGURATION
# =============================================================================
echo ""
echo "[FIRST-BOOT] Configuring graphics..."

# Detect GPU
if lspci | grep -qi "nvidia"; then
    echo "  NVIDIA GPU detected"
    # Check for proprietary drivers
    if ! dpkg -l | grep -q "nvidia-driver"; then
        echo "  Note: Proprietary NVIDIA drivers not installed"
        echo "  Consider installing: apt install nvidia-driver"
    fi
elif lspci | grep -qi "amd\|ati"; then
    echo "  AMD GPU detected"
    # Enable amdgpu if supported
    if modprobe amdgpu 2>/dev/null; then
        echo "  ✓ amdgpu module loaded"
    fi
elif lspci | grep -qi "intel"; then
    echo "  Intel GPU detected"
    # Enable i915
    if modprobe i915 2>/dev/null; then
        echo "  ✓ i915 module loaded"
    fi
fi

# Configure X11
if [ -d /etc/X11/xorg.conf.d ]; then
    # Create basic X11 config for better compatibility
    cat > /etc/X11/xorg.conf.d/99-taaos.conf << 'EOF'
# TaaOS X11 Configuration
Section "ServerFlags"
    Option "AutoAddGPU" "true"
    Option "AutoAddDevices" "true"
EndSection

Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "us"
    Option "XkbModel" "pc105"
EndSection
EOF
fi

# =============================================================================
# SECTION 7: STORAGE OPTIMIZATION
# =============================================================================
echo ""
echo "[FIRST-BOOT] Optimizing storage..."

# Detect SSD
SSD_COUNT=$(lsblk -d -o NAME,ROTA | grep "0$" | wc -l)
if [ "$SSD_COUNT" -gt 0 ]; then
    echo "  SSD detected ($SSD_COUNT device(s))"
    
    # Enable TRIM
    systemctl enable fstrim.timer
    systemctl start fstrim.timer 2>/dev/null || true
    echo "  ✓ TRIM enabled"
    
    # Enable SSD-specific mount options
    if [ -f /etc/fstab ]; then
        # Check if noatime is already set
        if ! grep -q "noatime" /etc/fstab; then
            echo "  Note: Consider adding 'noatime' to /etc/fstab for SSD optimization"
        fi
    fi
else
    echo "  HDD detected (no SSD optimization needed)"
fi

# =============================================================================
# SECTION 8: SECURITY CONFIGURATION
# =============================================================================
echo ""
echo "[FIRST-BOOT] Configuring security..."

# Update package lists
if command -v apt-get >/dev/null 2>&1; then
    echo "  Updating package lists..."
    apt-get update -qq 2>/dev/null || echo "  ✗ Failed to update package lists"
fi

# Configure firewall (ufw)
if command -v ufw >/dev/null 2>&1; then
    echo "  Configuring UFW firewall..."
    ufw default deny incoming 2>/dev/null || true
    ufw default allow outgoing 2>/dev/null || true
    ufw allow ssh 2>/dev/null || true
    # Don't enable yet, let user decide
    echo "  ✓ UFW configured (not enabled - use 'ufw enable' to activate)"
fi

# Configure fail2ban
if [ -f /etc/fail2ban/jail.conf ]; then
    systemctl enable fail2ban 2>/dev/null || true
    echo "  ✓ fail2ban enabled"
fi

# =============================================================================
# SECTION 9: DEVELOPMENT ENVIRONMENT
# =============================================================================
echo ""
echo "[FIRST-BOOT] Configuring development environment..."

# Update Python alternatives
if command -v python3 >/dev/null 2>&1; then
    update-alternatives --set python3 /usr/bin/python3.11 2>/dev/null || true
fi

# Configure Node.js if installed
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo "  Node.js: $NODE_VERSION"
fi

# Configure Rust if installed
if [ -d /usr/local/cargo ]; then
    echo "  Rust environment configured"
fi

# =============================================================================
# SECTION 10: FINALIZATION
# =============================================================================
echo ""
echo "[FIRST-BOOT] Finalizing configuration..."

# Update icon cache
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
fi

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi

# Update mime database
if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database /usr/share/mime 2>/dev/null || true
fi

# Create marker file to prevent re-running
touch /var/lib/taaos/first-boot-complete

# Mark first-boot as complete
systemctl disable taaos-first-boot.service 2>/dev/null || true

echo ""
echo "=============================================="
echo "[TaaOS] First Boot Configuration Complete!"
echo "=============================================="
echo ""
echo "System is now fully configured and ready to use."
echo "Log file: $LOGFILE"
echo ""
echo "Next steps:"
echo "  1. Reboot if required"
echo "  2. Login with your user account"
echo "  3. Run 'taaos-welcome' for a quick tour"
echo ""
