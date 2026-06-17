#!/bin/bash
# =============================================================================
# TaaOS User Environment Setup
# =============================================================================
# Script: 02-user-env.sh
# Purpose: Configure Neofetch with TaaOS branding and wallpaper collection
# Color Scheme: Rosso Corsa (#D40000) + Off-White (#F5F5F5) + Black (#0A0A0A)
# =============================================================================

set -e

echo "=============================================="
echo "  TaaOS User Environment Setup"
echo "=============================================="

# -----------------------------------------------------------------------------
# SECTION 1: NEOFETCH WITH TAAOS ASCII ART
# -----------------------------------------------------------------------------
setup_neofetch() {
    echo "[USER-ENV] Installing Neofetch..."
    apt-get update
    apt-get install -y neofetch

    echo "[USER-ENV] Creating TaaOS Neofetch configuration..."
    
    # Create skeleton config directory
    mkdir -p /etc/skel/.config/neofetch
    
    # Generate custom Neofetch config - Rosso Corsa theme
    # Color 1 = Red (Rosso Corsa), Color 7 = White (Off-White)
    cat > /etc/skel/.config/neofetch/config.conf << 'NEOFETCH_CONFIG'
# =============================================================================
# TaaOS Neofetch Configuration - Rosso Corsa Edition
# =============================================================================

print_info() {
    info title
    info underline

    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "Resolution" resolution
    info "DE" de
    info "WM" wm
    info "WM Theme" wm_theme
    info "Theme" theme
    info "Icons" icons
    info "Terminal" term
    info "Terminal Font" term_font
    info "CPU" cpu
    info "GPU" gpu
    info "Memory" memory
    info "Disk" disk
    info "Local IP" local_ip

    info cols
}

# Custom TaaOS ASCII Art
ascii_distro="taaos"

# Title
title_fqdn="off"

# Kernel
kernel_shorthand="on"

# Distro
distro_shorthand="off"
os_arch="on"

# Uptime
uptime_shorthand="on"

# Memory
memory_percent="on"
memory_unit="gib"

# Packages
package_managers="on"

# Shell
shell_path="off"
shell_version="on"

# CPU
speed_type="bios_limit"
speed_shorthand="on"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
cpu_temp="on"

# GPU
gpu_brand="on"
gpu_type="all"

# Resolution
refresh_rate="on"

# Disk
disk_show=('/')
disk_subtitle="mount"
disk_percent="on"

# Text Colors - Rosso Corsa (1=red) + Off-White (7=white)
colors=(1 7 1 7 7 1)

# Text Options
bold="on"
underline_enabled="on"
underline_char="-"
separator=":"

# Color Blocks
block_range=(0 15)
color_blocks="on"
block_width=3
block_height=1
col_offset="auto"

# Progress Bars
bar_char_elapsed="-"
bar_char_total="="
bar_border="on"
bar_length=15
bar_color_elapsed="distro"
bar_color_total="distro"

# Info display
cpu_display="bar"
memory_display="bar"
battery_display="bar"
disk_display="bar"

# Backend Settings
image_backend="ascii"
image_source="auto"

# Ascii Options - Red and White
ascii_colors=(1 7)
ascii_bold="on"

# Image Options
image_loop="off"
thumbnail_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/thumbnails/neofetch"
crop_mode="normal"
crop_offset="center"
image_size="auto"
gap=3
yoffset=0
xoffset=0
background_color=

# Misc Options
stdout="off"
NEOFETCH_CONFIG

    # Create TaaOS ASCII art file - Rosso Corsa theme
    mkdir -p /usr/share/neofetch/ascii/distro
    
    # c1 = Red (Rosso Corsa), c2 = White (Off-White)
    cat > /usr/share/neofetch/ascii/distro/taaos << 'TAAOS_ASCII'
${c1}
        ████████╗ █████╗  █████╗  ██████╗ ███████╗
        ╚══██╔══╝██╔══██╗██╔══██╗██╔═══██╗██╔════╝
           ██║   ███████║███████║██║   ██║███████╗
           ██║   ██╔══██║██╔══██║██║   ██║╚════██║
           ██║   ██║  ██║██║  ██║╚██████╔╝███████║
           ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
${c2}
    ╔═══════════════════════════════════════════════════╗
    ║  ${c1}Engineering Excellence${c2}  │  ${c1}Custom Kernel${c2}  │  ${c1}AI${c2}  ║
    ╚═══════════════════════════════════════════════════╝
${c1}
           ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
          █ ${c2}Debian Bookworm${c1} │ ${c2}Linux Kernel -taaos${c1} █
           ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
TAAOS_ASCII

    # Create symlink for neofetch to find the ascii
    ln -sf /usr/share/neofetch/ascii/distro/taaos /usr/share/neofetch/ascii/distro/taaos_small 2>/dev/null || true

    # Add neofetch to bashrc for all users
    cat >> /etc/skel/.bashrc << 'BASHRC_NEOFETCH'

# TaaOS - Display system info on login
if command -v neofetch &> /dev/null; then
    neofetch --ascii_distro taaos
fi
BASHRC_NEOFETCH

    echo "[USER-ENV] Neofetch setup completed!"
}

# -----------------------------------------------------------------------------
# SECTION 2: WALLPAPER COLLECTION - BLACK + ROSSO CORSA
# -----------------------------------------------------------------------------
setup_wallpapers() {
    echo "[USER-ENV] Setting up TaaOS wallpaper collection..."
    
    # Create wallpaper directory
    WALLPAPER_DIR="/usr/share/backgrounds/taaos"
    mkdir -p "${WALLPAPER_DIR}"
    
    # Check for local wallpapers first
    LOCAL_WALLPAPERS="/opt/taaos/assets/wallpapers"
    
    if [ -d "${LOCAL_WALLPAPERS}" ] && [ "$(ls -A ${LOCAL_WALLPAPERS} 2>/dev/null)" ]; then
        echo "[USER-ENV] Copying local wallpapers..."
        cp -r "${LOCAL_WALLPAPERS}"/* "${WALLPAPER_DIR}/" 2>/dev/null || true
    else
        echo "[USER-ENV] No local wallpapers found, downloading dark collection..."
        
        # Download dark wallpapers
        curl -L -o "${WALLPAPER_DIR}/taaos-dark-abstract.jpg" \
            "https://images.unsplash.com/photo-1557682250-33bd709cbe85?w=1920&q=80" \
            2>/dev/null || echo "[USER-ENV] Could not download wallpaper 1"
        
        curl -L -o "${WALLPAPER_DIR}/taaos-dark-minimal.jpg" \
            "https://images.unsplash.com/photo-1557683316-973673baf926?w=1920&q=80" \
            2>/dev/null || echo "[USER-ENV] Could not download wallpaper 2"
    fi
    
    # Create fallback wallpapers - Black + Rosso Corsa theme
    if [ ! "$(ls -A ${WALLPAPER_DIR}/*.jpg ${WALLPAPER_DIR}/*.png 2>/dev/null)" ]; then
        echo "[USER-ENV] Creating Rosso Corsa themed wallpapers..."
        
        if command -v convert &> /dev/null; then
            # Pure black with subtle red gradient at bottom
            convert -size 1920x1080 \
                -define gradient:direction=south \
                gradient:'#0A0A0A-#1A0000' \
                "${WALLPAPER_DIR}/taaos-default.png"
            
            # Black with red accent stripe
            convert -size 1920x1080 xc:'#0A0A0A' \
                -fill '#D40000' -draw "rectangle 0,1060 1920,1080" \
                "${WALLPAPER_DIR}/taaos-rosso-stripe.png"
            
            # Dark gradient
            convert -size 1920x1080 \
                -define gradient:direction=southeast \
                gradient:'#0A0A0A-#121212' \
                "${WALLPAPER_DIR}/taaos-dark.png"
                
            echo "[USER-ENV] Rosso Corsa wallpapers created!"
        else
            echo "[USER-ENV] ImageMagick not available, skipping fallback creation"
        fi
    fi
    
    # Create XFCE desktop background list
    mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
    
    cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << 'XFCE_DESKTOP'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVirtual1" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/taaos/taaos-default.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XFCE_DESKTOP

    # Set proper permissions
    chmod -R 755 "${WALLPAPER_DIR}"
    
    echo "[USER-ENV] Wallpaper collection setup completed!"
}

# -----------------------------------------------------------------------------
# SECTION 3: ADDITIONAL USER ENVIRONMENT TWEAKS
# -----------------------------------------------------------------------------
setup_user_tweaks() {
    echo "[USER-ENV] Applying additional user environment tweaks..."
    
    # Create .profile additions
    cat >> /etc/skel/.profile << 'PROFILE_ADDITIONS'

# TaaOS User Environment
export EDITOR=nano
export VISUAL=nano
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

# Path additions
export PATH="$HOME/.local/bin:$PATH"
PROFILE_ADDITIONS

    # Create default directories
    mkdir -p /etc/skel/.local/bin
    mkdir -p /etc/skel/.config
    mkdir -p /etc/skel/.cache
    mkdir -p /etc/skel/Documents
    mkdir -p /etc/skel/Downloads
    mkdir -p /etc/skel/Projects
    
    echo "[USER-ENV] User tweaks applied!"
}

# -----------------------------------------------------------------------------
# SECTION 4: THEME SWITCHER & XFCE DEFAULTS
# -----------------------------------------------------------------------------
setup_theme_system() {
    echo "[USER-ENV] Setting up TaaOS theme system..."
    
    # Install theme switcher script
    if [ -f "/build/scripts/ux/theme-switcher.sh" ]; then
        cp /build/scripts/ux/theme-switcher.sh /usr/local/bin/taaos-theme
        chmod +x /usr/local/bin/taaos-theme
        echo "[USER-ENV] Theme switcher installed: taaos-theme"
    fi
    
    # Create XFCE4 Terminal configuration (defaults to dark)
    mkdir -p /etc/skel/.config/xfce4/terminal
    cat > /etc/skel/.config/xfce4/terminal/terminalrc << 'TERMINAL_CONFIG'
[Configuration]
FontName=Fira Code 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=100x30
MiscInheritGeometry=FALSE
MiscMenubarDefault=TRUE
MiscMouseAutohide=FALSE
MiscMouseWheelZoom=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=TRUE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscMiddleClickOpensUri=FALSE
MiscCopyOnSelect=FALSE
MiscShowRelaunchDialog=TRUE
MiscRewrapOnResize=TRUE
MiscUseShiftArrowsToScroll=FALSE
MiscSlimTabs=FALSE
MiscNewTabAdjacent=FALSE
MiscSearchDialogOpacity=100
MiscShowUnsafePasteDialog=TRUE
ScrollingUnlimited=TRUE
BackgroundMode=TERMINAL_BACKGROUND_SOLID
ColorForeground=#F5F5F5
ColorBackground=#0A0A0A
ColorCursor=#D40000
ColorCursorUseDefault=FALSE
ColorSelection=#D40000
ColorSelectionBackground=#3A3A3A
ColorPalette=#0A0A0A;#D40000;#00AA00;#AAAA00;#5555FF;#AA00AA;#00AAAA;#AAAAAA;#555555;#FF5555;#55FF55;#FFFF55;#5555FF;#FF55FF;#55FFFF;#F5F5F5
TERMINAL_CONFIG

    # Create XFCE4 Panel configuration (defaults to dark with off-white option)
    mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
    cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'PANEL_CONFIG'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="32"/>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.96"/>
        <value type="double" value="0.96"/>
        <value type="double" value="0.96"/>
        <value type="double" value="1"/>
      </property>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-4" type="string" value="systray"/>
    <property name="plugin-5" type="string" value="statusnotifier"/>
    <property name="plugin-6" type="string" value="clock"/>
    <property name="plugin-7" type="string" value="actions"/>
  </property>
</channel>
PANEL_CONFIG

    # Create light mode wallpaper
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 \
            -define gradient:direction=south \
            gradient:'#F5F5F5-#E8E8E8' \
            /usr/share/backgrounds/taaos/taaos-light.png 2>/dev/null || true
        echo "[USER-ENV] Light mode wallpaper created"
    fi
    
    # Add theme switcher alias
    cat >> /etc/skel/.bashrc << 'THEME_ALIAS'

# TaaOS Theme Switcher
alias theme='taaos-theme'
alias dark='taaos-theme dark'
alias light='taaos-theme light'
THEME_ALIAS

    # Create default theme setting (starts with dark mode but light panel - Windows style)
    mkdir -p /etc/skel/.config/taaos
    echo "dark" > /etc/skel/.config/taaos/theme
    
    # Create desktop shortcut for theme switcher
    mkdir -p /etc/skel/Desktop
    cat > /etc/skel/Desktop/theme-switcher.desktop << 'THEME_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=TaaOS Theme
Comment=Toggle between Dark and Light themes
Icon=preferences-desktop-theme
Exec=taaos-theme toggle
Terminal=false
Categories=Settings;DesktopSettings;
THEME_DESKTOP
    chmod +x /etc/skel/Desktop/theme-switcher.desktop
    
    echo "[USER-ENV] Theme system setup completed!"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "[USER-ENV] Starting TaaOS User Environment Setup..."
    echo "[USER-ENV] Theme: Rosso Corsa + Off-White Panel"
    echo ""

    setup_neofetch
    echo ""
    
    setup_wallpapers
    echo ""
    
    setup_user_tweaks
    echo ""
    
    setup_theme_system
    echo ""

    echo "=============================================="
    echo "  TaaOS User Environment Setup - COMPLETE!"
    echo "=============================================="
}

# Run main function
main "$@"
