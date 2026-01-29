#!/bin/bash
# =============================================================================
# TaaOS Common Library - Shared Functions for Build System
# =============================================================================
# Source this file in all TaaOS build scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/common.sh"
# =============================================================================

# Strict mode
set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================
TAAOS_LOG_DIR="${TAAOS_LOG_DIR:-./logs}"
TAAOS_BUILD_ID="${TAAOS_BUILD_ID:-$(date +%Y%m%d_%H%M%S)}"
TAAOS_LOG_FILE="${TAAOS_LOG_DIR}/build_${TAAOS_BUILD_ID}.log"
TAAOS_MIN_DISK_GB="${TAAOS_MIN_DISK_GB:-20}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Console output with color
    echo -e "${color}[${timestamp}] [${level}]${NC} ${message}"
    
    # File output without color (if log dir exists)
    if [[ -d "${TAAOS_LOG_DIR}" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "${TAAOS_LOG_FILE}"
    fi
}

log_info() {
    _log "INFO" "${BLUE}" "$*"
}

log_warn() {
    _log "WARN" "${YELLOW}" "$*"
}

log_error() {
    _log "ERROR" "${RED}" "$*" >&2
}

log_success() {
    _log "SUCCESS" "${GREEN}" "$*"
}

log_phase() {
    local phase_name="$1"
    echo ""
    _log "PHASE" "${CYAN}" "═══════════════════════════════════════════════════"
    _log "PHASE" "${CYAN}" "  ${phase_name}"
    _log "PHASE" "${CYAN}" "═══════════════════════════════════════════════════"
    echo ""
}

# =============================================================================
# ERROR HANDLING
# =============================================================================
_error_handler() {
    local exit_code=$?
    local line_number=$1
    local command="$2"
    
    log_error "Command failed at line ${line_number}: ${command}"
    log_error "Exit code: ${exit_code}"
    
    # Call cleanup function if defined
    if declare -f taaos_cleanup > /dev/null 2>&1; then
        log_warn "Running cleanup handler..."
        taaos_cleanup || true
    fi
    
    exit "${exit_code}"
}

enable_error_trap() {
    trap '_error_handler ${LINENO} "$BASH_COMMAND"' ERR
}

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
check_docker() {
    log_info "Checking Docker availability..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed!"
        return 2
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running!"
        return 2
    fi
    
    log_success "Docker is available"
    return 0
}

check_disk_space() {
    local required_gb="${1:-${TAAOS_MIN_DISK_GB}}"
    local target_dir="${2:-.}"
    
    log_info "Checking disk space (minimum ${required_gb}GB required)..."
    
    local available_kb
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows Git Bash
        available_kb=$(df -k "$target_dir" 2>/dev/null | awk 'NR==2 {print $4}')
    else
        # Linux
        available_kb=$(df -k "$target_dir" 2>/dev/null | awk 'NR==2 {print $4}')
    fi
    
    if [[ -z "$available_kb" ]]; then
        log_warn "Could not determine disk space, continuing anyway..."
        return 0
    fi
    
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [[ "$available_gb" -lt "$required_gb" ]]; then
        log_error "Insufficient disk space: ${available_gb}GB available, ${required_gb}GB required"
        return 4
    fi
    
    log_success "Disk space OK: ${available_gb}GB available"
    return 0
}

check_network() {
    local host="${1:-deb.debian.org}"
    local timeout="${2:-5}"
    
    log_info "Checking network connectivity to ${host}..."
    
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout "${timeout}" "https://${host}" > /dev/null 2>&1; then
            log_success "Network connectivity OK"
            return 0
        fi
    elif command -v ping &> /dev/null; then
        if ping -c 1 -W "${timeout}" "${host}" > /dev/null 2>&1; then
            log_success "Network connectivity OK"
            return 0
        fi
    fi
    
    log_warn "Cannot reach ${host} - network may be unavailable"
    return 3
}

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: ${cmd}"
        return 1
    fi
    return 0
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
init_logging() {
    mkdir -p "${TAAOS_LOG_DIR}"
    touch "${TAAOS_LOG_FILE}"
    log_info "Log file: ${TAAOS_LOG_FILE}"
}

run_with_retry() {
    local max_attempts="${1}"
    local delay="${2}"
    shift 2
    local cmd=("$@")
    
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt ${attempt}/${max_attempts}: ${cmd[*]}"
        
        if "${cmd[@]}"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Command failed, retrying in ${delay} seconds..."
            sleep "$delay"
        fi
        
        ((attempt++))
    done
    
    log_error "Command failed after ${max_attempts} attempts"
    return 1
}

measure_time() {
    local start_time=$SECONDS
    "$@"
    local exit_code=$?
    local elapsed=$((SECONDS - start_time))
    log_info "Completed in ${elapsed} seconds"
    return $exit_code
}

# =============================================================================
# PREFLIGHT SUITE
# =============================================================================
run_preflight_checks() {
    log_phase "PRE-FLIGHT CHECKS"
    
    local failed=0
    
    check_docker || failed=1
    check_disk_space || failed=1
    check_network "deb.debian.org" || log_warn "Proceeding without network verification"
    check_network "github.com" || log_warn "Proceeding without GitHub verification"
    
    if [[ $failed -eq 1 ]]; then
        log_error "Pre-flight checks failed!"
        return 1
    fi
    
    log_success "All pre-flight checks passed"
    return 0
}

# Initialize logging if script is being executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "TaaOS Common Library - Not meant to be executed directly"
    echo "Source this file in your scripts instead"
    exit 1
fi
