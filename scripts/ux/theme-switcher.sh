#!/bin/bash
# =============================================================================
# TaaOS Unified Theme Switcher CLI (Dark / Light & Accent Modes)
# =============================================================================
# Script: theme-switcher.sh
# Purpose: Toggle between Dark and Light modes and accent palettes
# Location: /usr/local/bin/taaos-theme
# =============================================================================

USER_CONFIG_JSON="$HOME/.config/taaos/theme.json"
USER_CONFIG_LEGACY="$HOME/.config/taaos/theme"

mkdir -p "$HOME/.config/taaos"

get_current_mode() {
    if [ -f "$USER_CONFIG_JSON" ]; then
        python3 -c "import json; print(json.load(open('$USER_CONFIG_JSON')).get('mode', 'dark'))" 2>/dev/null || echo "dark"
    elif [ -f "$USER_CONFIG_LEGACY" ]; then
        cat "$USER_CONFIG_LEGACY"
    else
        echo "dark"
    fi
}

apply_mode() {
    local target_mode="$1"
    echo "$target_mode" > "$USER_CONFIG_LEGACY"
    if [ -x /usr/local/bin/taaos-appearance ]; then
        /usr/local/bin/taaos-appearance "$target_mode"
    fi
}

show_help() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║       TaaOS Theme Switcher               ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo "Usage / Kullanım: taaos-theme [COMMAND]"
    echo ""
    echo "Commands / Komutlar:"
    echo "  dark      🌙 Dark Mode / Karanlık Mod"
    echo "  light     ☀️  Light Mode / Aydınlık Mod"
    echo "  toggle    🔄 Toggle Dark/Light / Mod Değiştir"
    echo "  gui       🎨 Open Appearance Studio / Görünüm Stüdyosu"
    echo "  status    ℹ️  Show current mode / Mevcut modu göster"
    echo "  help      ❓ Show this help / Yardım"
    echo ""
    echo "Current mode / Mevcut mod: $(get_current_mode)"
    echo ""
}

case "${1:-toggle}" in
    dark)
        apply_mode "dark"
        echo "✓ TaaOS Theme: DARK MODE (🌙)"
        ;;
    light)
        apply_mode "light"
        echo "✓ TaaOS Theme: LIGHT MODE (☀️)"
        ;;
    toggle)
        if [ -x /usr/local/bin/taaos-appearance ]; then
            /usr/local/bin/taaos-appearance toggle-mode
        else
            current=$(get_current_mode)
            if [ "$current" = "dark" ]; then
                apply_mode "light"
            else
                apply_mode "dark"
            fi
        fi
        echo "✓ TaaOS Theme: $(get_current_mode | tr '[:lower:]' '[:upper:]') MODE"
        ;;
    gui|studio)
        exec /usr/local/bin/taaos-appearance
        ;;
    red|cyan|purple|emerald|amber)
        if [ -x /usr/local/bin/taaos-appearance ]; then
            /usr/local/bin/taaos-appearance "$1"
        fi
        ;;
    status)
        echo "Current mode / Mevcut mod: $(get_current_mode)"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command / Bilinmeyen komut: $1"
        show_help
        exit 1
        ;;
esac
