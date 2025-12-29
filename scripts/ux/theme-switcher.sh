#!/bin/bash
# =============================================================================
# TaaOS Theme Switcher
# =============================================================================
# Script: theme-switcher.sh
# Purpose: Toggle between Dark and Light themes
# Location: /usr/local/bin/taaos-theme
# =============================================================================

# Color definitions
ROSSO_CORSA="#D40000"
OFF_WHITE="#F5F5F5"
PURE_BLACK="#0A0A0A"

THEME_DIR="/usr/share/taaos/themes"
USER_CONFIG="$HOME/.config/taaos/theme"

# Create directories
mkdir -p "$HOME/.config/taaos"
mkdir -p "$THEME_DIR"

# Get current theme
get_current_theme() {
    if [ -f "$USER_CONFIG" ]; then
        cat "$USER_CONFIG"
    else
        echo "dark"
    fi
}

# Set XFCE panel to off-white (light mode)
apply_light_theme() {
    echo "light" > "$USER_CONFIG"
    
    # XFCE4 Panel - Off-white background
    xfconf-query -c xfce4-panel -p /panels/panel-1/background-style -s 1 2>/dev/null
    xfconf-query -c xfce4-panel -p /panels/panel-1/background-rgba -s 0.96 -s 0.96 -s 0.96 -s 1.0 2>/dev/null
    
    # GTK Theme - Light
    xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita" 2>/dev/null
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus" 2>/dev/null
    
    # XFWM4 (Window Manager) - Light
    xfconf-query -c xfwm4 -p /general/theme -s "Default" 2>/dev/null
    
    # Terminal - Light background
    if [ -f "$HOME/.config/xfce4/terminal/terminalrc" ]; then
        sed -i 's/ColorBackground=.*/ColorBackground=#F5F5F5/' "$HOME/.config/xfce4/terminal/terminalrc"
        sed -i 's/ColorForeground=.*/ColorForeground=#0A0A0A/' "$HOME/.config/xfce4/terminal/terminalrc"
    fi
    
    # Desktop - Light wallpaper
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/last-image \
        -s "/usr/share/backgrounds/taaos/taaos-light.png" 2>/dev/null
    
    echo "✓ Tema: LIGHT MODE (Kırık Beyaz Panel)"
    echo "  - Panel: Off-White"
    echo "  - Metin: Siyah"
    echo "  - Vurgular: Rosso Corsa"
}

# Set XFCE panel to black (dark mode)
apply_dark_theme() {
    echo "dark" > "$USER_CONFIG"
    
    # XFCE4 Panel - Black background
    xfconf-query -c xfce4-panel -p /panels/panel-1/background-style -s 1 2>/dev/null
    xfconf-query -c xfce4-panel -p /panels/panel-1/background-rgba -s 0.04 -s 0.04 -s 0.04 -s 1.0 2>/dev/null
    
    # GTK Theme - Dark
    xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark" 2>/dev/null
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark" 2>/dev/null
    
    # XFWM4 (Window Manager) - Dark
    xfconf-query -c xfwm4 -p /general/theme -s "Default-hdpi" 2>/dev/null
    
    # Terminal - Dark background
    if [ -f "$HOME/.config/xfce4/terminal/terminalrc" ]; then
        sed -i 's/ColorBackground=.*/ColorBackground=#0A0A0A/' "$HOME/.config/xfce4/terminal/terminalrc"
        sed -i 's/ColorForeground=.*/ColorForeground=#F5F5F5/' "$HOME/.config/xfce4/terminal/terminalrc"
    fi
    
    # Desktop - Dark wallpaper
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/last-image \
        -s "/usr/share/backgrounds/taaos/taaos-default.png" 2>/dev/null
    
    echo "✓ Tema: DARK MODE (Siyah Panel)"
    echo "  - Panel: Saf Siyah"
    echo "  - Metin: Kırık Beyaz"
    echo "  - Vurgular: Rosso Corsa"
}

# Toggle between themes
toggle_theme() {
    current=$(get_current_theme)
    
    if [ "$current" = "dark" ]; then
        apply_light_theme
    else
        apply_dark_theme
    fi
}

# Show help
show_help() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║       TaaOS Theme Switcher               ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo "Kullanım: taaos-theme [KOMUT]"
    echo ""
    echo "Komutlar:"
    echo "  dark      Koyu tema (siyah panel, beyaz metin)"
    echo "  light     Açık tema (beyaz panel, siyah metin)"
    echo "  toggle    Temalar arası geçiş yap"
    echo "  status    Mevcut temayı göster"
    echo "  help      Bu yardım mesajını göster"
    echo ""
    echo "Mevcut tema: $(get_current_theme)"
    echo ""
}

# Main
case "${1:-toggle}" in
    dark)
        apply_dark_theme
        ;;
    light)
        apply_light_theme
        ;;
    toggle)
        toggle_theme
        ;;
    status)
        echo "Mevcut tema: $(get_current_theme)"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Bilinmeyen komut: $1"
        show_help
        exit 1
        ;;
esac
