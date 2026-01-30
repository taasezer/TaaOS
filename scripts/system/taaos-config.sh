#!/bin/bash
# =============================================================================
# TaaOS Configuration Tool
# =============================================================================
# Unified system settings management
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/taaos/config.log"

# =============================================================================
# LOGGING
# =============================================================================
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $*" >> "$LOG_FILE"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; log "[INFO] $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; log "[SUCCESS] $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; log "[WARN] $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; log "[ERROR] $*"; }

# =============================================================================
# MENU
# =============================================================================
check_dialog() {
    command -v dialog &> /dev/null
}

show_menu_dialog() {
    dialog --clear --backtitle "TaaOS Configuration" \
        --title "System Settings" \
        --menu "Select an option:" 20 60 10 \
        1 "Display Settings" \
        2 "Network Configuration" \
        3 "Development Environment" \
        4 "Services (Docker, SSH, etc.)" \
        5 "Firewall & Security" \
        6 "Performance Tuning" \
        7 "Backup & Snapshot" \
        8 "Update Preferences" \
        9 "Advanced Settings" \
        0 "Exit" \
        2>&1 >/dev/tty
}

show_menu_text() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               TaaOS Configuration                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  [1] Display Settings"
    echo "  [2] Network Configuration"
    echo "  [3] Development Environment"
    echo "  [4] Services (Docker, SSH, etc.)"
    echo "  [5] Firewall & Security"
    echo "  [6] Performance Tuning"
    echo "  [7] Backup & Snapshot"
    echo "  [8] Update Preferences"
    echo "  [9] Advanced Settings"
    echo "  [0] Exit"
    echo ""
    read -p "Select option [0-9]: " choice
    echo "$choice"
}

# =============================================================================
# DISPLAY SETTINGS
# =============================================================================
configure_display() {
    echo ""
    log_info "Display Settings"
    echo ""
    
    # Show current displays
    echo -e "${BLUE}Current displays:${NC}"
    xrandr --query 2>/dev/null | grep " connected" || echo "  No displays detected (no X server)"
    echo ""
    
    echo "[1] List available resolutions"
    echo "[2] Set resolution"
    echo "[3] Set refresh rate"
    echo "[4] Configure multiple monitors"
    echo "[0] Back"
    echo ""
    read -p "Select: " display_choice
    
    case "$display_choice" in
        1)
            xrandr --query 2>/dev/null || log_error "xrandr not available"
            ;;
        2)
            read -p "Enter output (e.g., HDMI-1): " output
            read -p "Enter resolution (e.g., 1920x1080): " resolution
            xrandr --output "$output" --mode "$resolution" && log_success "Resolution set!"
            ;;
        3)
            read -p "Enter output: " output
            read -p "Enter resolution: " resolution
            read -p "Enter refresh rate: " rate
            xrandr --output "$output" --mode "$resolution" --rate "$rate" && log_success "Set!"
            ;;
        4)
            log_info "Use 'arandr' for graphical multi-monitor setup"
            command -v arandr &>/dev/null && arandr || apt-get install -y arandr
            ;;
    esac
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================
configure_network() {
    log_info "Opening Network Manager TUI..."
    
    if command -v nmtui &> /dev/null; then
        nmtui
    else
        log_error "NetworkManager TUI not available"
        log_info "Use 'ip addr' and 'ip route' for manual configuration"
    fi
}

# =============================================================================
# DEVELOPMENT ENVIRONMENT
# =============================================================================
configure_dev_env() {
    echo ""
    log_info "Development Environment Setup"
    echo ""
    
    echo "[1] Configure Git"
    echo "[2] Generate SSH Key"
    echo "[3] Configure VS Code"
    echo "[4] Set Default Editor"
    echo "[5] Install Dev Tools"
    echo "[0] Back"
    echo ""
    read -p "Select: " dev_choice
    
    case "$dev_choice" in
        1) configure_git ;;
        2) generate_ssh_key ;;
        3) configure_vscode ;;
        4) configure_editor ;;
        5) install_dev_tools ;;
    esac
}

configure_git() {
    echo ""
    read -p "Git username: " git_user
    read -p "Git email: " git_email
    
    git config --global user.name "$git_user"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor "vim"
    git config --global pull.rebase false
    
    log_success "Git configured for $git_user <$git_email>"
}

generate_ssh_key() {
    local ssh_dir="$HOME/.ssh"
    local key_file="$ssh_dir/id_ed25519"
    
    if [[ -f "$key_file" ]]; then
        log_warn "SSH key already exists: $key_file"
        read -p "Generate new key? [y/N]: " overwrite
        [[ ! "$overwrite" =~ ^[Yy]$ ]] && return
    fi
    
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    read -p "Email for SSH key: " email
    ssh-keygen -t ed25519 -C "$email" -f "$key_file"
    
    log_success "SSH key generated!"
    echo ""
    echo -e "${CYAN}Public key (copy to GitHub/GitLab):${NC}"
    cat "${key_file}.pub"
}

configure_vscode() {
    if ! command -v code &> /dev/null; then
        log_warn "VS Code not installed"
        read -p "Install VS Code? [y/N]: " install_vscode
        if [[ "$install_vscode" =~ ^[Yy]$ ]]; then
            taaos-pkg install code 2>/dev/null || log_error "Install failed"
        fi
        return
    fi
    
    local settings_dir="$HOME/.config/Code/User"
    mkdir -p "$settings_dir"
    
    cat > "$settings_dir/settings.json" << 'EOF'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "'Fira Code', 'Courier New', monospace",
    "editor.fontLigatures": true,
    "editor.tabSize": 4,
    "editor.formatOnSave": true,
    "workbench.colorTheme": "One Dark Pro",
    "terminal.integrated.defaultProfile.linux": "bash",
    "files.autoSave": "afterDelay",
    "files.trimTrailingWhitespace": true,
    "git.enableSmartCommit": true
}
EOF
    
    log_success "VS Code settings configured!"
}

configure_editor() {
    log_info "Available editors:"
    update-alternatives --list editor 2>/dev/null || echo "  vim, nano, emacs..."
    
    echo ""
    read -p "Select editor (vim/nano/emacs): " editor
    update-alternatives --set editor "/usr/bin/$editor" 2>/dev/null || {
        export EDITOR="$editor"
        echo "export EDITOR=$editor" >> ~/.bashrc
    }
    
    log_success "Default editor set to: $editor"
}

install_dev_tools() {
    log_info "Installing development tools..."
    
    if command -v taaos-pkg &> /dev/null; then
        taaos-pkg install sysdev
    else
        apt-get install -y build-essential git curl wget vim
    fi
    
    log_success "Development tools installed!"
}

# =============================================================================
# SERVICES
# =============================================================================
configure_services() {
    echo ""
    log_info "Service Management"
    echo ""
    
    # Show TaaOS services status
    echo -e "${BLUE}Service Status:${NC}"
    for svc in docker ssh cockpit.socket; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "  ${GREEN}●${NC} $svc (running)"
        else
            echo -e "  ${RED}○${NC} $svc (stopped)"
        fi
    done
    echo ""
    
    echo "[1] Docker"
    echo "[2] SSH Server"
    echo "[3] Cockpit (Web Admin)"
    echo "[4] Enable All"
    echo "[5] Disable All"
    echo "[0] Back"
    echo ""
    read -p "Select: " svc_choice
    
    case "$svc_choice" in
        1) toggle_service "docker" ;;
        2) toggle_service "ssh" ;;
        3) toggle_service "cockpit.socket" ;;
        4) 
            for s in docker ssh cockpit.socket; do
                systemctl enable --now "$s" 2>/dev/null || true
            done
            log_success "All services enabled"
            ;;
        5)
            for s in docker ssh cockpit.socket; do
                systemctl disable --now "$s" 2>/dev/null || true
            done
            log_success "All services disabled"
            ;;
    esac
}

toggle_service() {
    local service="$1"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        read -p "$service is running. Stop it? [y/N]: " stop
        if [[ "$stop" =~ ^[Yy]$ ]]; then
            systemctl disable --now "$service"
            log_success "$service stopped and disabled"
        fi
    else
        read -p "$service is stopped. Start it? [y/N]: " start
        if [[ "$start" =~ ^[Yy]$ ]]; then
            systemctl enable --now "$service"
            log_success "$service started and enabled"
        fi
    fi
}

# =============================================================================
# FIREWALL
# =============================================================================
configure_firewall() {
    echo ""
    log_info "Firewall & Security"
    echo ""
    
    if ! command -v ufw &> /dev/null; then
        log_warn "UFW not installed"
        read -p "Install UFW? [y/N]: " install_ufw
        if [[ "$install_ufw" =~ ^[Yy]$ ]]; then
            apt-get install -y ufw
        else
            return
        fi
    fi
    
    echo -e "${BLUE}Current status:${NC}"
    ufw status verbose
    echo ""
    
    echo "[1] Enable firewall"
    echo "[2] Disable firewall"
    echo "[3] Allow SSH (port 22)"
    echo "[4] Allow HTTP/HTTPS (80, 443)"
    echo "[5] Allow custom port"
    echo "[0] Back"
    echo ""
    read -p "Select: " fw_choice
    
    case "$fw_choice" in
        1) ufw enable && log_success "Firewall enabled" ;;
        2) ufw disable && log_success "Firewall disabled" ;;
        3) ufw allow ssh && log_success "SSH allowed" ;;
        4) ufw allow http && ufw allow https && log_success "HTTP/HTTPS allowed" ;;
        5)
            read -p "Port number: " port
            ufw allow "$port" && log_success "Port $port allowed"
            ;;
    esac
}

# =============================================================================
# PERFORMANCE
# =============================================================================
configure_performance() {
    echo ""
    log_info "Performance Tuning"
    echo ""
    
    echo "[1] Show system resources"
    echo "[2] Adjust swappiness"
    echo "[3] Enable zRAM"
    echo "[4] Limit journald size"
    echo "[0] Back"
    echo ""
    read -p "Select: " perf_choice
    
    case "$perf_choice" in
        1)
            echo -e "${BLUE}CPU:${NC}"
            lscpu | grep "Model name"
            echo -e "${BLUE}Memory:${NC}"
            free -h
            echo -e "${BLUE}Disk:${NC}"
            df -h /
            ;;
        2)
            current=$(cat /proc/sys/vm/swappiness)
            echo "Current swappiness: $current (lower = less swap usage)"
            read -p "New value (0-100): " new_swappiness
            echo "$new_swappiness" > /proc/sys/vm/swappiness
            echo "vm.swappiness=$new_swappiness" >> /etc/sysctl.conf
            log_success "Swappiness set to $new_swappiness"
            ;;
        3)
            if ! lsmod | grep -q zram; then
                modprobe zram
                echo lz4 > /sys/block/zram0/comp_algorithm
                echo 2G > /sys/block/zram0/disksize
                mkswap /dev/zram0
                swapon /dev/zram0
                log_success "zRAM enabled (2GB)"
            else
                log_info "zRAM already active"
            fi
            ;;
        4)
            echo "SystemMaxUse=100M" >> /etc/systemd/journald.conf
            systemctl restart systemd-journald
            log_success "Journal size limited to 100MB"
            ;;
    esac
}

# =============================================================================
# BACKUP
# =============================================================================
configure_backup() {
    log_info "Opening TaaOS Rescue Tool..."
    
    if command -v taaos-rescue &> /dev/null; then
        taaos-rescue
    else
        log_warn "taaos-rescue not found, using timeshift directly"
        timeshift-gtk 2>/dev/null || timeshift --list
    fi
}

# =============================================================================
# UPDATES
# =============================================================================
configure_updates() {
    log_info "Opening TaaOS Update Tool..."
    
    if command -v taaos-update &> /dev/null; then
        taaos-update status
        echo ""
        read -p "Check for updates now? [y/N]: " check
        if [[ "$check" =~ ^[Yy]$ ]]; then
            taaos-update check
        fi
    else
        log_warn "Update tool not found"
    fi
}

# =============================================================================
# ADVANCED
# =============================================================================
configure_advanced() {
    echo ""
    log_info "Advanced Settings"
    log_warn "⚠️  These settings can affect system stability!"
    echo ""
    
    echo "[1] Edit GRUB configuration"
    echo "[2] View kernel parameters"
    echo "[3] Edit sysctl settings"
    echo "[4] Manage kernel modules"
    echo "[0] Back"
    echo ""
    read -p "Select: " adv_choice
    
    case "$adv_choice" in
        1)
            ${EDITOR:-vim} /etc/default/grub
            update-grub
            log_success "GRUB updated"
            ;;
        2)
            cat /proc/cmdline
            ;;
        3)
            ${EDITOR:-vim} /etc/sysctl.conf
            sysctl -p
            log_success "sysctl reloaded"
            ;;
        4)
            echo "Loaded modules:"
            lsmod | head -20
            ;;
    esac
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    while true; do
        local choice
        
        if check_dialog; then
            choice=$(show_menu_dialog) || break
        else
            choice=$(show_menu_text)
        fi
        
        clear
        
        case "$choice" in
            1) configure_display ;;
            2) configure_network ;;
            3) configure_dev_env ;;
            4) configure_services ;;
            5) configure_firewall ;;
            6) configure_performance ;;
            7) configure_backup ;;
            8) configure_updates ;;
            9) configure_advanced ;;
            0|"") break ;;
            *) log_error "Invalid option: $choice" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
    
    clear
    log_info "TaaOS Configuration exited"
}

# Handle --help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "TaaOS Configuration Tool"
    echo ""
    echo "Usage: taaos-config"
    echo ""
    echo "Interactive system configuration for:"
    echo "  - Display settings"
    echo "  - Network configuration"
    echo "  - Development environment"
    echo "  - System services"
    echo "  - Firewall & security"
    echo "  - Performance tuning"
    exit 0
fi

main "$@"
