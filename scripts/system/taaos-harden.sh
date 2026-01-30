#!/bin/bash
# =============================================================================
# TaaOS Security Hardening Tool
# =============================================================================
# Implements security best practices for production systems
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/taaos/security.log"

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
        log_info "Try: sudo taaos-harden"
        exit 1
    fi
}

# =============================================================================
# FIREWALL (UFW)
# =============================================================================
setup_firewall() {
    log_info "🔥 Configuring firewall (UFW)..."
    
    if ! command -v ufw &> /dev/null; then
        log_info "Installing UFW..."
        apt-get install -y ufw
    fi
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow essential services
    ufw allow ssh comment 'SSH access'
    ufw allow http comment 'HTTP web'
    ufw allow https comment 'HTTPS web'
    
    # Enable firewall
    echo "y" | ufw enable
    
    log_success "Firewall configured!"
    ufw status verbose
}

# =============================================================================
# FAIL2BAN
# =============================================================================
setup_fail2ban() {
    log_info "🛡️ Configuring Fail2ban..."
    
    if ! command -v fail2ban-client &> /dev/null; then
        log_info "Installing Fail2ban..."
        apt-get install -y fail2ban
    fi
    
    # Create TaaOS jail config
    cat > /etc/fail2ban/jail.d/taaos.conf << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h
EOF
    
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    log_success "Fail2ban configured!"
}

# =============================================================================
# SYSCTL HARDENING
# =============================================================================
setup_sysctl() {
    log_info "🔧 Configuring kernel security parameters..."
    
    cat > /etc/sysctl.d/99-taaos-security.conf << 'EOF'
# TaaOS Security Hardening - Kernel Parameters

# Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Log Martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
EOF
    
    sysctl -p /etc/sysctl.d/99-taaos-security.conf
    
    log_success "Kernel security parameters applied!"
}

# =============================================================================
# SSH HARDENING
# =============================================================================
setup_ssh() {
    log_info "🔐 Hardening SSH configuration..."
    
    local ssh_config="/etc/ssh/sshd_config.d/99-taaos-hardening.conf"
    
    cat > "$ssh_config" << 'EOF'
# TaaOS SSH Hardening

# Disable root login
PermitRootLogin no

# Use public key authentication
PubkeyAuthentication yes

# Disable password authentication (uncomment after setting up keys)
# PasswordAuthentication no

# Disable X11 forwarding
X11Forwarding no

# Limit authentication attempts
MaxAuthTries 3

# Client timeout settings
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable empty passwords
PermitEmptyPasswords no

# Disable protocol 1
Protocol 2

# Use secure algorithms
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512
EOF
    
    # Validate config before restart
    if sshd -t 2>/dev/null; then
        systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
        log_success "SSH hardened!"
    else
        log_warn "SSH config validation failed, skipping restart"
        rm -f "$ssh_config"
    fi
    
    log_warn "⚠️  Password auth is still enabled. After setting up SSH keys, run:"
    log_warn "   sudo sed -i 's/# PasswordAuthentication no/PasswordAuthentication no/' $ssh_config"
}

# =============================================================================
# SECURITY AUDIT
# =============================================================================
run_audit() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  SECURITY AUDIT${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Firewall status
    echo -e "${BLUE}Firewall:${NC}"
    if ufw status 2>/dev/null | grep -q "active"; then
        echo -e "  ${GREEN}●${NC} UFW is active"
    else
        echo -e "  ${RED}○${NC} UFW is not active"
    fi
    
    # Fail2ban status
    echo -e "${BLUE}Fail2ban:${NC}"
    if systemctl is-active fail2ban &>/dev/null; then
        echo -e "  ${GREEN}●${NC} Fail2ban is running"
        fail2ban-client status 2>/dev/null | grep "Jail list" || true
    else
        echo -e "  ${RED}○${NC} Fail2ban is not running"
    fi
    
    # SSH config
    echo -e "${BLUE}SSH:${NC}"
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config* 2>/dev/null; then
        echo -e "  ${GREEN}●${NC} Root login disabled"
    else
        echo -e "  ${YELLOW}●${NC} Root login may be enabled"
    fi
    
    # Sysctl
    echo -e "${BLUE}Sysctl:${NC}"
    if [[ -f /etc/sysctl.d/99-taaos-security.conf ]]; then
        echo -e "  ${GREEN}●${NC} Security sysctl active"
    else
        echo -e "  ${RED}○${NC} Security sysctl not configured"
    fi
    
    # Open ports
    echo ""
    echo -e "${BLUE}Open ports:${NC}"
    ss -tulpn 2>/dev/null | grep LISTEN | head -10 || netstat -tulpn 2>/dev/null | grep LISTEN | head -10
    
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
show_menu() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              TaaOS Security Hardening                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  [1] Full hardening (recommended)"
    echo "  [2] Firewall only (UFW)"
    echo "  [3] Fail2ban only"
    echo "  [4] Sysctl only"
    echo "  [5] SSH hardening only"
    echo "  [6] Security audit"
    echo "  [q] Exit"
    echo ""
    read -p "Select: " choice
    echo "$choice"
}

main() {
    check_root
    
    case "${1:-menu}" in
        full|all)
            setup_firewall
            setup_fail2ban
            setup_sysctl
            setup_ssh
            echo ""
            log_success "🔒 Full security hardening complete!"
            ;;
        firewall|ufw)
            setup_firewall
            ;;
        fail2ban)
            setup_fail2ban
            ;;
        sysctl)
            setup_sysctl
            ;;
        ssh)
            setup_ssh
            ;;
        audit|status)
            run_audit
            ;;
        menu|"")
            while true; do
                choice=$(show_menu)
                clear
                case "$choice" in
                    1) setup_firewall; setup_fail2ban; setup_sysctl; setup_ssh ;;
                    2) setup_firewall ;;
                    3) setup_fail2ban ;;
                    4) setup_sysctl ;;
                    5) setup_ssh ;;
                    6) run_audit ;;
                    q|Q|"") break ;;
                    *) echo "Invalid option" ;;
                esac
                read -p "Press Enter to continue..."
            done
            ;;
        --help|-h)
            echo "TaaOS Security Hardening Tool"
            echo ""
            echo "Usage: taaos-harden [command]"
            echo ""
            echo "Commands:"
            echo "  full       Full hardening (firewall, fail2ban, sysctl, SSH)"
            echo "  firewall   Configure UFW firewall"
            echo "  fail2ban   Setup brute-force protection"
            echo "  sysctl     Apply kernel security parameters"
            echo "  ssh        Harden SSH configuration"
            echo "  audit      Run security audit"
            ;;
    esac
}

main "$@"
