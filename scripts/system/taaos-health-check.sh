#!/bin/bash
# =============================================================================
# TaaOS Health Check Script
# =============================================================================
# Boot-time system health verification
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/var/log/taaos/health-check.log"
HEALTH_STATUS=0

# =============================================================================
# LOGGING
# =============================================================================
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

check_pass() { echo -e "  ${GREEN}✓${NC} $*"; log "[PASS] $*"; }
check_fail() { echo -e "  ${RED}✗${NC} $*"; log "[FAIL] $*"; HEALTH_STATUS=1; }
check_warn() { echo -e "  ${YELLOW}!${NC} $*"; log "[WARN] $*"; }

# =============================================================================
# HEALTH CHECKS
# =============================================================================
check_disk_space() {
    echo -e "\n${BLUE}[Disk Space]${NC}"
    
    local usage
    usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    
    if [[ $usage -lt 80 ]]; then
        check_pass "Root filesystem: ${usage}% used"
    elif [[ $usage -lt 95 ]]; then
        check_warn "Root filesystem: ${usage}% used (low space)"
    else
        check_fail "Root filesystem: ${usage}% used (critical!)"
    fi
}

check_memory() {
    echo -e "\n${BLUE}[Memory]${NC}"
    
    local total available percent
    total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    percent=$((100 - (available * 100 / total)))
    
    if [[ $percent -lt 80 ]]; then
        check_pass "Memory: ${percent}% used"
    elif [[ $percent -lt 95 ]]; then
        check_warn "Memory: ${percent}% used (high)"
    else
        check_fail "Memory: ${percent}% used (critical!)"
    fi
}

check_essential_services() {
    echo -e "\n${BLUE}[Essential Services]${NC}"
    
    local services=("systemd-journald" "dbus" "NetworkManager")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            check_pass "$service is running"
        else
            check_warn "$service is not running"
        fi
    done
}

check_docker() {
    echo -e "\n${BLUE}[Docker]${NC}"
    
    if command -v docker &> /dev/null; then
        if systemctl is-active --quiet docker 2>/dev/null; then
            check_pass "Docker daemon is running"
        else
            check_warn "Docker is installed but not running"
        fi
    else
        check_warn "Docker is not installed"
    fi
}

check_network() {
    echo -e "\n${BLUE}[Network]${NC}"
    
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        check_pass "Internet connectivity OK"
    else
        check_warn "No internet connection"
    fi
    
    if ping -c 1 -W 2 github.com &> /dev/null; then
        check_pass "GitHub reachable"
    else
        check_warn "Cannot reach GitHub"
    fi
}

check_taaos_version() {
    echo -e "\n${BLUE}[TaaOS Version]${NC}"
    
    if [[ -f /etc/taaos/version ]]; then
        local version
        version=$(cat /etc/taaos/version)
        check_pass "TaaOS version: v$version"
    else
        check_warn "Version file not found"
    fi
}

check_pending_updates() {
    echo -e "\n${BLUE}[Updates]${NC}"
    
    if [[ -f /var/lib/taaos/pending_update ]]; then
        local pending
        pending=$(cat /var/lib/taaos/pending_update)
        check_warn "Pending update: v$pending"
    else
        check_pass "No pending updates"
    fi
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              TaaOS Health Check                                  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    check_taaos_version
    check_disk_space
    check_memory
    check_essential_services
    check_docker
    check_network
    check_pending_updates
    
    echo ""
    if [[ $HEALTH_STATUS -eq 0 ]]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}  System health: GOOD${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}  System health: ISSUES DETECTED${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    echo ""
    
    exit $HEALTH_STATUS
}

main "$@"
