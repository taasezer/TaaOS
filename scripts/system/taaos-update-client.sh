#!/bin/bash
# =============================================================================
# TaaOS Update Client
# =============================================================================
# GitHub-based OTA update system with rollback support
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================
TAAOS_VERSION="1.0.0"
REPO_URL="https://raw.githubusercontent.com/taasezer/TaaOS/main/releases"
VERSION_FILE="/etc/taaos/version"
UPDATE_CACHE="/var/cache/taaos/updates"
LOG_FILE="/var/log/taaos/update.log"
PENDING_UPDATE_FILE="/var/lib/taaos/pending_update"
SCRIPT_NAME="taaos-update"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
        log_error "This command requires root privileges"
        log_info "Try: sudo $SCRIPT_NAME $*"
        exit 1
    fi
}

check_dependencies() {
    local deps=("curl" "jq" "sha256sum" "wget")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Required command not found: $dep"
            log_info "Install with: apt install $dep"
            exit 1
        fi
    done
}

check_network() {
    if ! curl -fsSL --max-time 5 "https://github.com" &> /dev/null; then
        log_error "No internet connection"
        return 1
    fi
    return 0
}

# =============================================================================
# VERSION MANAGEMENT
# =============================================================================
get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        # Fallback to default
        echo "$TAAOS_VERSION"
    fi
}

set_current_version() {
    local version="$1"
    mkdir -p "$(dirname "$VERSION_FILE")"
    echo "$version" > "$VERSION_FILE"
}

# Semantic version comparison: returns 0 if $1 > $2
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# =============================================================================
# UPDATE CHECK
# =============================================================================
fetch_version_info() {
    local max_retries=3
    local retry_delay=5
    
    for i in $(seq 1 $max_retries); do
        if curl -fsSL --max-time 10 "$REPO_URL/version.json" -o /tmp/taaos-version.json 2>/dev/null; then
            return 0
        fi
        log_warn "GitHub connection failed, retrying... ($i/$max_retries)"
        sleep $retry_delay
    done
    
    log_error "Failed to fetch version info from GitHub"
    return 1
}

check_for_updates() {
    log_info "Checking for updates..."
    
    local current_version
    current_version=$(get_current_version)
    log_info "Current version: v$current_version"
    
    if ! check_network; then
        log_warn "Cannot check updates (no internet)"
        return 1
    fi
    
    if ! fetch_version_info; then
        return 1
    fi
    
    # Parse version info
    local latest_version
    local update_available
    local breaking_changes
    
    latest_version=$(jq -r '.current_version' /tmp/taaos-version.json)
    update_available=$(jq -r '.update_available' /tmp/taaos-version.json)
    breaking_changes=$(jq -r '.breaking_changes' /tmp/taaos-version.json)
    
    log_info "Latest version: v$latest_version"
    
    if version_gt "$latest_version" "$current_version"; then
        log_success "🎉 Update available: v$latest_version"
        echo ""
        
        # Show changelog preview
        show_changelog_preview "$latest_version"
        
        if [[ "$breaking_changes" == "true" ]]; then
            log_warn "⚠️  This update contains breaking changes!"
            log_warn "⚠️  Please backup your data before updating!"
        fi
        
        # Store pending update for reminder
        mkdir -p "$(dirname "$PENDING_UPDATE_FILE")"
        echo "$latest_version" > "$PENDING_UPDATE_FILE"
        
        echo ""
        log_info "Run 'sudo taaos-update now' to install the update"
        return 0
    else
        log_success "✅ System is up to date (v$current_version)"
        rm -f "$PENDING_UPDATE_FILE"
        return 0
    fi
}

show_changelog_preview() {
    local version="$1"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  CHANGES IN v$version${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if curl -fsSL "$REPO_URL/changelog.json" -o /tmp/taaos-changelog.json 2>/dev/null; then
        jq -r --arg ver "$version" '
            .versions[] | select(.version == $ver) |
            "Date: \(.date)\n" +
            (if .changes.added | length > 0 then "Added:\n" + (.changes.added | map("  ✓ " + .) | join("\n")) + "\n" else "" end) +
            (if .changes.fixed | length > 0 then "Fixed:\n" + (.changes.fixed | map("  🔧 " + .) | join("\n")) + "\n" else "" end) +
            (if .changes.security | length > 0 then "Security:\n" + (.changes.security | map("  🔒 " + .) | join("\n")) else "" end)
        ' /tmp/taaos-changelog.json 2>/dev/null || echo "  (changelog unavailable)"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# =============================================================================
# UPDATE EXECUTION
# =============================================================================
perform_update() {
    local target_version="${1:-}"
    
    if [[ -z "$target_version" ]]; then
        if [[ -f "$PENDING_UPDATE_FILE" ]]; then
            target_version=$(cat "$PENDING_UPDATE_FILE")
        else
            log_error "No pending update. Run 'taaos-update check' first."
            return 1
        fi
    fi
    
    log_info "🚀 Starting update to v$target_version"
    
    # Step 1: Pre-update snapshot
    create_snapshot "pre-update-$target_version"
    
    # Step 2: Download update package
    log_info "📦 Downloading update package..."
    mkdir -p "$UPDATE_CACHE"
    
    local patch_url
    patch_url=$(jq -r --arg ver "$target_version" \
        '.versions[] | select(.version == $ver) | .patch_url // empty' \
        /tmp/taaos-changelog.json 2>/dev/null || echo "")
    
    if [[ -z "$patch_url" ]]; then
        # Fallback: use full ISO download URL
        patch_url=$(jq -r '.download_url' /tmp/taaos-version.json)
        log_warn "No patch available, full update required"
    fi
    
    if ! wget -q --show-progress "$patch_url" -O "$UPDATE_CACHE/update.tar.gz" 2>/dev/null; then
        log_error "Failed to download update package"
        return 1
    fi
    
    # Step 3: Verify checksum
    log_info "🔍 Verifying update package..."
    
    local expected_checksum
    local actual_checksum
    expected_checksum=$(jq -r '.checksum.sha256' /tmp/taaos-version.json)
    actual_checksum=$(sha256sum "$UPDATE_CACHE/update.tar.gz" | awk '{print $1}')
    
    if [[ "$expected_checksum" != "$actual_checksum" ]] && [[ "$expected_checksum" != "null" ]]; then
        log_error "Checksum mismatch! Update package may be corrupted."
        rm -f "$UPDATE_CACHE/update.tar.gz"
        return 1
    fi
    
    log_success "✅ Update package verified"
    
    # Step 4: Apply update
    log_info "⚙️  Applying update..."
    
    cd "$UPDATE_CACHE"
    tar -xzf update.tar.gz 2>/dev/null || {
        log_warn "Could not extract update (may be ISO)"
    }
    
    # Run update script if present
    if [[ -f "$UPDATE_CACHE/update.sh" ]]; then
        chmod +x "$UPDATE_CACHE/update.sh"
        if ! bash "$UPDATE_CACHE/update.sh"; then
            log_error "Update script failed!"
            log_warn "Rolling back..."
            rollback_update
            return 1
        fi
    fi
    
    # Step 5: Update system packages
    log_info "📦 Updating system packages..."
    apt-get update -qq
    apt-get upgrade -y -qq
    
    # Step 6: Update version file
    set_current_version "$target_version"
    rm -f "$PENDING_UPDATE_FILE"
    
    # Cleanup
    rm -rf "$UPDATE_CACHE"/*
    
    log_success "🎉 Update to v$target_version complete!"
    log_info "A system reboot is recommended."
}

# =============================================================================
# SNAPSHOT & ROLLBACK
# =============================================================================
create_snapshot() {
    local name="$1"
    
    log_info "📸 Creating system snapshot..."
    
    if command -v timeshift &> /dev/null; then
        timeshift --create --comments "$name" --scripted 2>/dev/null || {
            log_warn "Timeshift snapshot failed (continuing anyway)"
        }
        log_success "Snapshot created: $name"
    else
        log_warn "Timeshift not installed - no snapshot created"
        log_info "Install with: taaos-pkg install timeshift"
    fi
}

rollback_update() {
    log_info "🔄 Rolling back to previous version..."
    
    if command -v timeshift &> /dev/null; then
        log_info "Available snapshots:"
        timeshift --list 2>/dev/null || true
        
        echo ""
        log_info "To rollback, run: sudo timeshift --restore"
    else
        log_error "Timeshift not installed. Manual rollback required."
    fi
}

# =============================================================================
# HELP
# =============================================================================
show_help() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║              TaaOS Update System                                 ║
╚══════════════════════════════════════════════════════════════════╝

USAGE:
  taaos-update <command>

COMMANDS:
  check       Check for available updates
  now         Download and install pending update
  rollback    Rollback to previous version (via Timeshift)
  status      Show current version and update status
  help        Show this help message

EXAMPLES:
  taaos-update check      # Check for updates
  taaos-update now        # Install pending update
  taaos-update status     # Show current version

CONFIGURATION:
  Version file:  /etc/taaos/version
  Update cache:  /var/cache/taaos/updates
  Log file:      /var/log/taaos/update.log

EOF
}

show_status() {
    local current_version
    current_version=$(get_current_version)
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              TaaOS System Status                                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Version:        ${GREEN}v$current_version${NC}"
    
    if [[ -f "$PENDING_UPDATE_FILE" ]]; then
        local pending
        pending=$(cat "$PENDING_UPDATE_FILE")
        echo -e "  Update pending: ${YELLOW}v$pending${NC}"
        echo -e "  Run 'sudo taaos-update now' to install"
    else
        echo -e "  Update pending: ${GREEN}None${NC}"
    fi
    
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        check)
            check_dependencies
            check_for_updates
            ;;
        now|update|install)
            check_root
            check_dependencies
            perform_update "${1:-}"
            ;;
        rollback)
            check_root
            rollback_update
            ;;
        status)
            show_status
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
