#!/bin/bash
# =============================================================================
# TaaOS Modular Suite — Common Helper Library
# =============================================================================
# Provides standardized colors, banners, internationalization (TR/EN),
# environment detection, and package helpers for all 'taaos-*' modular tools.
# =============================================================================

# Colors (Rosso Corsa Red + Dark Theme accents)
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# =============================================================================
# LANGUAGE & LOCALIZATION (Bilingual Engine)
# =============================================================================
# Default to English ("en") globally, switch to Turkish ("tr") if system locale is Turkish.
TAAOS_LANG="en"
_SYS_LOCALE="${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}"
if [[ "$_SYS_LOCALE" =~ ^tr ]]; then
    TAAOS_LANG="tr"
fi

# Allow manual override via command line flag --lang=tr / --lang=en or env TAAOS_LANG
for arg in "$@"; do
    case "$arg" in
        --lang=tr) TAAOS_LANG="tr" ;;
        --lang=en) TAAOS_LANG="en" ;;
    esac
done

# Translation helper: t "Turkish String" "English String"
t() {
    if [ "$TAAOS_LANG" = "tr" ]; then
        echo -e "$1"
    else
        echo -e "$2"
    fi
}

# Standardized Logging
log_info()    { echo -e "${CYAN}[$(t 'BİLGİ' 'INFO')]${NC} $*"; }
log_success() { echo -e "${GREEN}[$(t 'BAŞARILI' 'SUCCESS')]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[$(t 'UYARI' 'WARNING')]${NC} $*"; }
log_error()   { echo -e "${RED}[$(t 'HATA' 'ERROR')]${NC} $*" >&2; }

# Environment Detection
is_wsl() {
    if [ -f /proc/sys/fs/binfmt_misc/WSLCommandLine ] || grep -qi microsoft /proc/version 2>/dev/null; then
        return 0
    fi
    return 1
}

# Header Banner (Clean ANSI, No Escaped Byte Miscalculations)
taaos_banner() {
    local title="$1"
    local subtitle="${2:-TaaOS Modular Environment Suite}"
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}${title}${NC}"
    if [ -n "$subtitle" ]; then
        echo -e "${RED}║${NC}  ${DIM}${subtitle}${NC}"
    fi
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if command is installed
is_cmd_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Check if dpkg package is installed
is_pkg_installed() {
    dpkg -s "$1" 2>/dev/null | grep -q "Status: install ok installed"
}

# Print status indicator with optional educational description
print_status_item() {
    local name="$1"
    local cmd="$2"
    local ver_cmd="${3:-}"
    local desc="${4:-}"

    if is_cmd_installed "$cmd"; then
        local ver=""
        if [ -n "$ver_cmd" ]; then
            ver=$(eval "$ver_cmd" 2>/dev/null | head -1 | tr -d '\r')
        fi
        local status_str
        if [ -n "$ver" ]; then
            status_str="$(t 'Kurulu' 'Installed'): $ver"
        else
            status_str="$(t 'Kurulu' 'Installed')"
        fi
        printf "  ${GREEN}[✓]${NC} %-18s ${DIM}(%s - %s)${NC}\n" "$name" "$status_str" "$(command -v "$cmd")"
        if [ -n "$desc" ]; then
            printf "      ${DIM}└─ %s${NC}\n" "$desc"
        fi
        return 0
    else
        printf "  ${RED}[○]${NC} %-18s ${DIM}(%s)${NC}\n" "$name" "$(t 'Kurulu değil' 'Not installed')"
        if [ -n "$desc" ]; then
            printf "      ${DIM}└─ %s${NC}\n" "$desc"
        fi
        return 0
    fi
}

# Confirm action (Bilingual Y/N)
confirm() {
    local prompt="$1"
    local default="${2:-Y}"
    local response
    
    local choices="[Y/n]"
    [ "$TAAOS_LANG" = "tr" ] && choices="[E/h]"
    if [ "$default" != "Y" ]; then
        choices="[y/N]"
        [ "$TAAOS_LANG" = "tr" ] && choices="[e/H]"
    fi
    
    echo -ne "${YELLOW}${prompt} ${choices}: ${NC}"
    read -r response
    response=${response:-$default}
    case "$response" in
        [eE][vV][eE][tT]|[eE]|[yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Run apt with sudo non-interactively
taaos_apt_install() {
    log_info "$(t 'APT paketleri kuruluyor:' 'Installing APT packages:') $*"
    if [ "$EUID" -ne 0 ]; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
    else
        DEBIAN_FRONTEND=noninteractive apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
    fi
}

taaos_apt_remove() {
    log_info "$(t 'APT paketleri kaldırılıyor:' 'Removing APT packages:') $*"
    if [ "$EUID" -ne 0 ]; then
        sudo apt-get remove -y --purge "$@"
        sudo apt-get autoremove -y
    else
        apt-get remove -y --purge "$@"
        apt-get autoremove -y
    fi
}
