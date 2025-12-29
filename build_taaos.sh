#!/bin/bash
# =============================================================================
#
#  ████████╗ █████╗  █████╗  ██████╗ ███████╗
#  ╚══██╔══╝██╔══██╗██╔══██╗██╔═══██╗██╔════╝
#     ██║   ███████║███████║██║   ██║███████╗
#     ██║   ██╔══██║██╔══██║██║   ██║╚════██║
#     ██║   ██║  ██║██║  ██║╚██████╔╝███████║
#     ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
#
#  TaaOS Master Build Script
#  Engineering Excellence in Every Byte
#
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/build_taaos.log"
VERSION="1.0.0"

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${CYAN}[INFO]${NC} ${message}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[✓ SUCCESS]${NC} ${message}"
            ;;
        "WARNING")
            echo -e "${YELLOW}[⚠ WARNING]${NC} ${message}"
            ;;
        "ERROR")
            echo -e "${RED}[✗ ERROR]${NC} ${message}"
            ;;
        "STEP")
            echo -e "${MAGENTA}[→]${NC} ${BOLD}${message}${NC}"
            ;;
        "HEADER")
            echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${WHITE}${BOLD}  $message${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
            ;;
    esac
    
    # Log to file
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

log_info() { log_message "INFO" "$1"; }
log_success() { log_message "SUCCESS" "$1"; }
log_warning() { log_message "WARNING" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_step() { log_message "STEP" "$1"; }
log_header() { log_message "HEADER" "$1"; }

# =============================================================================
# PRIVILEGE CHECK
# =============================================================================
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (EUID 0)"
        log_info "Run with: sudo ./build_taaos.sh"
        exit 1
    fi
    log_success "Running with root privileges"
}

# =============================================================================
# SCRIPT RUNNERS
# =============================================================================
run_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    if [[ -f "$script_path" ]]; then
        log_step "Executing: $script_name"
        chmod +x "$script_path"
        
        if bash "$script_path"; then
            log_success "$script_name completed successfully"
            return 0
        else
            log_error "$script_name failed with exit code $?"
            return 1
        fi
    else
        log_warning "Script not found: $script_path"
        return 1
    fi
}

# =============================================================================
# MODULE RUNNERS
# =============================================================================
run_ux_module() {
    log_header "Phase 1: Visual Identity & UX"
    
    run_script "${SCRIPT_DIR}/scripts/ux/01-setup-branding.sh"
    run_script "${SCRIPT_DIR}/scripts/ux/02-user-env.sh"
    
    log_success "UX Module completed"
}

run_performance_module() {
    log_header "Phase 2a: Performance Optimization"
    
    run_script "${SCRIPT_DIR}/scripts/performance/optimize-system.sh"
    
    log_success "Performance Module completed"
}

run_security_module() {
    log_header "Phase 2b: Security Hardening"
    
    run_script "${SCRIPT_DIR}/scripts/security/harden-system.sh"
    
    log_success "Security Module completed"
}

run_devops_module() {
    log_header "Phase 3: DevOps Toolchain"
    
    run_script "${SCRIPT_DIR}/scripts/devops/install-containers.sh"
    run_script "${SCRIPT_DIR}/scripts/devops/install-admin-tools.sh"
    
    log_success "DevOps Module completed"
}

run_installer_module() {
    log_header "Phase 4: Installer Configuration"
    
    run_script "${SCRIPT_DIR}/scripts/core/setup-calamares.sh"
    
    log_success "Installer Module completed"
}

run_full_build() {
    log_header "TaaOS Full Build - All Modules"
    
    local start_time=$(date +%s)
    
    run_ux_module
    run_performance_module
    run_security_module
    run_devops_module
    run_installer_module
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_header "Build Complete!"
    log_success "Total build time: ${duration} seconds"
}

# =============================================================================
# MENU SYSTEM
# =============================================================================
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'

    ████████╗ █████╗  █████╗  ██████╗ ███████╗
    ╚══██╔══╝██╔══██╗██╔══██╗██╔═══██╗██╔════╝
       ██║   ███████║███████║██║   ██║███████╗
       ██║   ██╔══██║██╔══██║██║   ██║╚════██║
       ██║   ██║  ██║██║  ██║╚██████╔╝███████║
       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

        Master Build System v1.0.0
        Engineering Excellence in Every Byte

BANNER
    echo -e "${NC}"
}

show_menu() {
    echo -e "${WHITE}${BOLD}═══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}  Select Build Module:${NC}"
    echo -e "${WHITE}${BOLD}═══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} 🚀 Run Full Build (All Modules)"
    echo -e "  ${CYAN}2)${NC} 🎨 Run Only UX (Plymouth, LightDM, Neofetch)"
    echo -e "  ${YELLOW}3)${NC} ⚡ Run Only Performance (zRAM, TLP, Tuned)"
    echo -e "  ${RED}4)${NC} 🛡️  Run Only Security (Fail2ban, ClamAV, Lynis)"
    echo -e "  ${MAGENTA}5)${NC} 🐳 Run Only DevOps (Docker, Portainer, Cockpit)"
    echo -e "  ${BLUE}6)${NC} 💿 Run Only Installer (Calamares)"
    echo -e "  ${WHITE}7)${NC} 📋 View Build Log"
    echo -e "  ${WHITE}0)${NC} ❌ Exit"
    echo ""
    echo -e "${WHITE}${BOLD}═══════════════════════════════════════════════${NC}"
}

interactive_menu() {
    while true; do
        show_banner
        show_menu
        
        echo -n -e "${CYAN}Enter selection [0-7]: ${NC}"
        read -r choice
        
        case $choice in
            1)
                run_full_build
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                run_ux_module
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                run_performance_module
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                run_security_module
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                run_devops_module
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                run_installer_module
                echo ""
                read -p "Press Enter to continue..."
                ;;
            7)
                if [[ -f "$LOG_FILE" ]]; then
                    less "$LOG_FILE"
                else
                    log_warning "No log file found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0)
                log_info "Exiting TaaOS Build System"
                exit 0
                ;;
            *)
                log_error "Invalid selection: $choice"
                sleep 1
                ;;
        esac
    done
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================
show_help() {
    echo "TaaOS Master Build Script v${VERSION}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --full          Run full build (all modules)"
    echo "  --ux            Run only UX module"
    echo "  --performance   Run only Performance module"
    echo "  --security      Run only Security module"
    echo "  --devops        Run only DevOps module"
    echo "  --installer     Run only Installer module"
    echo "  --menu          Show interactive menu"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo ./build_taaos.sh --full"
    echo "  sudo ./build_taaos.sh --ux --security"
    echo "  sudo ./build_taaos.sh --menu"
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================
main() {
    # Initialize log file
    echo "=== TaaOS Build Log - $(date) ===" > "$LOG_FILE"
    
    # Check privileges
    check_privileges
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        interactive_menu
        exit 0
    fi
    
    # Process command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full)
                run_full_build
                shift
                ;;
            --ux)
                run_ux_module
                shift
                ;;
            --performance)
                run_performance_module
                shift
                ;;
            --security)
                run_security_module
                shift
                ;;
            --devops)
                run_devops_module
                shift
                ;;
            --installer)
                run_installer_module
                shift
                ;;
            --menu)
                interactive_menu
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    log_success "TaaOS Build completed successfully!"
}

# Run main function
main "$@"
