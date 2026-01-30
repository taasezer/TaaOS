#!/bin/bash
# =============================================================================
# TaaOS Boot Analyzer
# =============================================================================
# Analyze and optimize boot performance
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# ANALYSIS FUNCTIONS
# =============================================================================
show_boot_time() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  BOOT TIME SUMMARY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    systemd-analyze
    echo ""
}

show_blame() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  SLOWEST SERVICES (Top 20)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    systemd-analyze blame | head -20
    echo ""
}

show_critical_chain() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  CRITICAL CHAIN${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    systemd-analyze critical-chain
    echo ""
}

show_recommendations() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  OPTIMIZATION RECOMMENDATIONS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Check for commonly slow services
    local slow_services=(
        "NetworkManager-wait-online.service"
        "plymouth-quit-wait.service"
        "ModemManager.service"
        "bluetooth.service"
    )
    
    echo -e "${BLUE}Potentially disableable services:${NC}"
    for svc in "${slow_services[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            local time
            time=$(systemd-analyze blame 2>/dev/null | grep "$svc" | awk '{print $1}' || echo "N/A")
            echo -e "  ${YELLOW}●${NC} $svc ($time)"
            echo "    Disable: sudo systemctl disable $svc"
        fi
    done
    
    echo ""
    echo -e "${BLUE}General recommendations:${NC}"
    echo "  • Use SSD instead of HDD"
    echo "  • Reduce GRUB timeout (GRUB_TIMEOUT=2)"
    echo "  • Disable unused services"
    echo "  • Enable preload for frequently used apps"
    echo ""
}

optimize_boot() {
    echo ""
    echo -e "${YELLOW}⚠️  Boot Optimization${NC}"
    echo ""
    
    # Disable commonly slow optional services
    local optional_services=(
        "ModemManager.service"
        "bluetooth.service"
    )
    
    for svc in "${optional_services[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            echo -e "Disable $svc? [y/N]: "
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                systemctl disable "$svc"
                echo -e "${GREEN}✓${NC} Disabled $svc"
            fi
        fi
    done
    
    # Mask slow wait services
    echo ""
    echo "Mask NetworkManager-wait-online.service? [y/N]: "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        systemctl mask NetworkManager-wait-online.service
        echo -e "${GREEN}✓${NC} Masked (boot won't wait for network)"
    fi
    
    echo ""
    echo -e "${GREEN}Optimization complete!${NC}"
    echo "Reboot to see improvements."
}

generate_plot() {
    local output="${1:-/tmp/boot-plot.svg}"
    
    echo "Generating boot plot..."
    systemd-analyze plot > "$output"
    echo -e "${GREEN}✓${NC} Saved to: $output"
    
    if command -v xdg-open &>/dev/null; then
        xdg-open "$output" 2>/dev/null &
    fi
}

# =============================================================================
# MAIN
# =============================================================================
show_menu() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              TaaOS Boot Analyzer                             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  [1] Show boot time summary"
    echo "  [2] Show slowest services"
    echo "  [3] Show critical chain"
    echo "  [4] Show recommendations"
    echo "  [5] Optimize boot (interactive)"
    echo "  [6] Generate boot plot (SVG)"
    echo "  [a] Show all analysis"
    echo "  [q] Exit"
    echo ""
    read -p "Select: " choice
    echo "$choice"
}

main() {
    case "${1:-menu}" in
        time|summary)
            show_boot_time
            ;;
        blame|slow)
            show_blame
            ;;
        chain|critical)
            show_critical_chain
            ;;
        recommend*)
            show_recommendations
            ;;
        optimize)
            optimize_boot
            ;;
        plot)
            generate_plot "${2:-/tmp/boot-plot.svg}"
            ;;
        all)
            show_boot_time
            show_blame
            show_critical_chain
            show_recommendations
            ;;
        menu|"")
            while true; do
                choice=$(show_menu)
                clear
                case "$choice" in
                    1) show_boot_time ;;
                    2) show_blame ;;
                    3) show_critical_chain ;;
                    4) show_recommendations ;;
                    5) optimize_boot ;;
                    6) generate_plot ;;
                    a|A) show_boot_time; show_blame; show_critical_chain; show_recommendations ;;
                    q|Q|"") break ;;
                    *) echo "Invalid option" ;;
                esac
                read -p "Press Enter to continue..."
            done
            ;;
        --help|-h)
            echo "TaaOS Boot Analyzer"
            echo ""
            echo "Usage: taaos-boot-analyze [command]"
            echo ""
            echo "Commands:"
            echo "  time        Show boot time summary"
            echo "  blame       Show slowest services"
            echo "  chain       Show critical chain"
            echo "  recommend   Show recommendations"
            echo "  optimize    Interactive optimization"
            echo "  plot        Generate boot plot SVG"
            echo "  all         Show all analysis"
            ;;
    esac
}

main "$@"
