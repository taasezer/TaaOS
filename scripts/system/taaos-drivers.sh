#!/bin/bash
# =============================================================================
# TaaOS Hardware Detection & Driver Installation
# =============================================================================
# Detects hardware and installs appropriate drivers
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/taaos/drivers.log"
CONFIGURED_FLAG="/var/lib/taaos/.drivers_configured"

# =============================================================================
# LOGGING
# =============================================================================
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; log "[INFO] $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; log "[SUCCESS] $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; log "[WARN] $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; log "[ERROR] $*"; }

# =============================================================================
# PREREQUISITES
# =============================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This tool requires root privileges"
        log_info "Try: sudo taaos-drivers"
        exit 1
    fi
}

# =============================================================================
# HARDWARE DETECTION
# =============================================================================
detect_gpu() {
    log_info "Detecting GPU..."
    
    if lspci | grep -qi nvidia; then
        echo "nvidia"
        log "[GPU] NVIDIA detected"
    elif lspci | grep -qi "amd.*vga\|radeon"; then
        echo "amd"
        log "[GPU] AMD detected"
    elif lspci | grep -qi "intel.*vga\|intel.*graphics"; then
        echo "intel"
        log "[GPU] Intel detected"
    else
        echo "unknown"
        log "[GPU] Unknown/Generic"
    fi
}

detect_wifi() {
    log_info "Detecting WiFi adapter..."
    
    if lspci | grep -qi "intel.*wireless\|iwl"; then
        echo "intel"
    elif lspci | grep -qi "realtek\|rtl"; then
        echo "realtek"
    elif lspci | grep -qi "atheros\|qualcomm"; then
        echo "atheros"
    elif lspci | grep -qi "broadcom"; then
        echo "broadcom"
    else
        echo "unknown"
    fi
}

detect_bluetooth() {
    if lsusb | grep -qi bluetooth || hciconfig 2>/dev/null | grep -q hci; then
        echo "yes"
    else
        echo "no"
    fi
}

detect_touchpad() {
    if xinput list 2>/dev/null | grep -qi touchpad; then
        echo "yes"
    elif libinput list-devices 2>/dev/null | grep -qi touchpad; then
        echo "yes"
    else
        echo "no"
    fi
}

# =============================================================================
# DRIVER INSTALLATION
# =============================================================================
install_nvidia_drivers() {
    log_info "🎮 Installing NVIDIA drivers..."
    
    log_warn "This will install proprietary NVIDIA drivers."
    log_warn "A system reboot will be required."
    
    if [[ "${AUTO_INSTALL:-false}" != "true" ]]; then
        read -p "Continue? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "NVIDIA driver installation skipped"
            return 0
        fi
    fi
    
    # Add non-free repository
    log_info "Adding non-free repository..."
    if ! grep -q "non-free" /etc/apt/sources.list; then
        sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    fi
    
    apt-get update
    
    # Install drivers
    log_info "Installing nvidia-driver package..."
    apt-get install -y nvidia-driver
    
    # Install CUDA (optional)
    read -p "Install CUDA toolkit for AI/ML? [y/N]: " cuda_confirm
    if [[ "$cuda_confirm" =~ ^[Yy]$ ]]; then
        log_info "Installing CUDA toolkit..."
        apt-get install -y nvidia-cuda-toolkit nvidia-cuda-dev
        
        # Configure CUDA path
        cat > /etc/profile.d/cuda.sh << 'EOF'
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
EOF
        log_success "CUDA installed and configured"
    fi
    
    log_success "NVIDIA drivers installed!"
    log_warn "⚠️  Please reboot to activate: sudo reboot"
    log_info "Test after reboot: nvidia-smi"
}

install_amd_drivers() {
    log_info "🎮 Installing AMD GPU firmware..."
    
    apt-get install -y firmware-amd-graphics
    
    log_success "AMD GPU firmware installed!"
}

install_intel_drivers() {
    log_info "🎮 Intel GPU drivers are built into the kernel (i915)"
    log_success "Intel GPU ready!"
}

install_wifi_firmware() {
    local wifi_type="$1"
    
    log_info "📡 Installing WiFi firmware..."
    
    case "$wifi_type" in
        intel)
            apt-get install -y firmware-iwlwifi
            ;;
        realtek)
            apt-get install -y firmware-realtek
            ;;
        atheros)
            apt-get install -y firmware-atheros
            ;;
        broadcom)
            apt-get install -y firmware-b43-installer
            ;;
        *)
            apt-get install -y firmware-linux-nonfree
            ;;
    esac
    
    log_success "WiFi firmware installed!"
}

configure_bluetooth() {
    log_info "🔵 Configuring Bluetooth..."
    
    apt-get install -y bluetooth bluez blueman
    systemctl enable bluetooth
    systemctl start bluetooth
    
    log_success "Bluetooth configured!"
}

configure_touchpad() {
    log_info "👆 Configuring touchpad..."
    
    mkdir -p /etc/X11/xorg.conf.d
    
    cat > /etc/X11/xorg.conf.d/40-libinput.conf << 'EOF'
Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "AccelProfile" "adaptive"
    Option "ClickMethod" "clickfinger"
EndSection
EOF
    
    log_success "Touchpad configured with tap-to-click and natural scrolling!"
}

# =============================================================================
# MAIN DETECTION FLOW
# =============================================================================
run_detection() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           TaaOS Hardware Detection & Drivers                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # GPU Detection
    local gpu_type
    gpu_type=$(detect_gpu)
    
    case "$gpu_type" in
        nvidia)
            log_success "🎮 NVIDIA GPU detected"
            install_nvidia_drivers
            ;;
        amd)
            log_success "🎮 AMD GPU detected"
            install_amd_drivers
            ;;
        intel)
            log_success "🎮 Intel GPU detected"
            install_intel_drivers
            ;;
        *)
            log_info "Generic/Unknown GPU - using default drivers"
            ;;
    esac
    
    # WiFi Detection
    local wifi_type
    wifi_type=$(detect_wifi)
    
    if [[ "$wifi_type" != "unknown" ]]; then
        log_success "📡 WiFi adapter detected ($wifi_type)"
        install_wifi_firmware "$wifi_type"
    else
        log_info "No specific WiFi adapter detected"
    fi
    
    # Bluetooth Detection
    local bt_present
    bt_present=$(detect_bluetooth)
    
    if [[ "$bt_present" == "yes" ]]; then
        log_success "🔵 Bluetooth adapter detected"
        configure_bluetooth
    fi
    
    # Touchpad Detection
    local tp_present
    tp_present=$(detect_touchpad)
    
    if [[ "$tp_present" == "yes" ]]; then
        log_success "👆 Touchpad detected"
        configure_touchpad
    fi
    
    # Mark as configured
    mkdir -p "$(dirname "$CONFIGURED_FLAG")"
    date > "$CONFIGURED_FLAG"
    
    echo ""
    log_success "Hardware detection complete!"
}

show_status() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           TaaOS Hardware Status                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}GPU:${NC}"
    lspci | grep -i "vga\|3d\|display" || echo "  No GPU detected"
    echo ""
    
    echo -e "${BLUE}WiFi:${NC}"
    lspci | grep -i "network\|wireless" || echo "  No WiFi detected"
    echo ""
    
    echo -e "${BLUE}Bluetooth:${NC}"
    lsusb | grep -i bluetooth || echo "  No Bluetooth detected"
    echo ""
    
    if [[ -f "$CONFIGURED_FLAG" ]]; then
        echo -e "${GREEN}Drivers configured:${NC} $(cat "$CONFIGURED_FLAG")"
    else
        echo -e "${YELLOW}Drivers not yet configured${NC}"
    fi
}

show_help() {
    echo "TaaOS Hardware Detection & Driver Installation"
    echo ""
    echo "Usage: taaos-drivers [command]"
    echo ""
    echo "Commands:"
    echo "  detect      Run hardware detection and install drivers"
    echo "  status      Show current hardware status"
    echo "  nvidia      Install NVIDIA drivers only"
    echo "  wifi        Install WiFi firmware only"
    echo "  bluetooth   Configure Bluetooth only"
    echo "  touchpad    Configure touchpad only"
    echo "  help        Show this help message"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    local command="${1:-detect}"
    
    case "$command" in
        detect)
            check_root
            run_detection
            ;;
        status)
            show_status
            ;;
        nvidia)
            check_root
            install_nvidia_drivers
            ;;
        wifi)
            check_root
            local wifi_type
            wifi_type=$(detect_wifi)
            install_wifi_firmware "$wifi_type"
            ;;
        bluetooth)
            check_root
            configure_bluetooth
            ;;
        touchpad)
            check_root
            configure_touchpad
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
