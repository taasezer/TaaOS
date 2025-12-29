#!/bin/bash
# =============================================================================
# TaaOS Visual Identity - Boot & Login Branding
# =============================================================================
# Script: 01-setup-branding.sh
# Purpose: Configure Plymouth boot splash, LightDM login screen, and system logos
# Color Scheme: Rosso Corsa (#D40000) + Off-White (#F5F5F5) + Black (#0A0A0A)
# =============================================================================

set -e

echo "=============================================="
echo "  TaaOS Branding Setup - Boot & Login"
echo "=============================================="

# Color definitions
ROSSO_CORSA="#D40000"
OFF_WHITE="#F5F5F5"
PURE_BLACK="#0A0A0A"
DARK_BLACK="#121212"

# -----------------------------------------------------------------------------
# SECTION 1: PLYMOUTH BOOT SPLASH
# -----------------------------------------------------------------------------
setup_plymouth() {
    echo "[BRANDING] Installing Plymouth..."
    apt-get update
    apt-get install -y plymouth plymouth-themes

    echo "[BRANDING] Creating TaaOS Plymouth theme..."
    
    THEME_DIR="/usr/share/plymouth/themes/taaos"
    mkdir -p "${THEME_DIR}"

    # Create the main plymouth theme configuration
    cat > "${THEME_DIR}/taaos.plymouth" << 'PLYMOUTH_CONFIG'
[Plymouth Theme]
Name=TaaOS
Description=TaaOS Custom Boot Theme - Rosso Corsa Edition
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/taaos
ScriptFile=/usr/share/plymouth/themes/taaos/taaos.script
PLYMOUTH_CONFIG

    # Create the Plymouth script for animations
    # RGB values: Rosso Corsa (0.83, 0.0, 0.0), Off-White (0.96, 0.96, 0.96), Black (0.04, 0.04, 0.04)
    cat > "${THEME_DIR}/taaos.script" << 'PLYMOUTH_SCRIPT'
# TaaOS Plymouth Boot Script
# Rosso Corsa + Black Theme

# Window setup - Pure black background
Window.SetBackgroundTopColor(0.04, 0.04, 0.04);
Window.SetBackgroundBottomColor(0.02, 0.02, 0.02);

# Logo positioning
logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2 - 50);
logo.sprite.SetOpacity(1);

# Progress bar
progress_box.image = Image("progress_box.png");
progress_box.sprite = Sprite(progress_box.image);
progress_box.x = Window.GetWidth() / 2 - progress_box.image.GetWidth() / 2;
progress_box.y = Window.GetHeight() / 2 + 100;
progress_box.sprite.SetPosition(progress_box.x, progress_box.y, 0);

progress_bar.original_image = Image("progress_bar.png");
progress_bar.sprite = Sprite();
progress_bar.x = Window.GetWidth() / 2 - progress_bar.original_image.GetWidth() / 2;
progress_bar.y = Window.GetHeight() / 2 + 100;
progress_bar.sprite.SetPosition(progress_bar.x, progress_bar.y, 1);

# Boot progress callback
fun boot_progress_cb(time, progress) {
    if (progress_bar.original_image) {
        progress_bar.image = progress_bar.original_image.Scale(
            progress_bar.original_image.GetWidth() * progress,
            progress_bar.original_image.GetHeight()
        );
        progress_bar.sprite.SetImage(progress_bar.image);
    }
}
Plymouth.SetBootProgressFunction(boot_progress_cb);

# Text message display - Off-white text
message_sprite = Sprite();
message_sprite.SetPosition(Window.GetWidth() / 2, Window.GetHeight() - 50, 1);

fun message_cb(text) {
    # Off-white text color (0.96, 0.96, 0.96)
    message_image = Image.Text(text, 0.96, 0.96, 0.96);
    message_sprite.SetImage(message_image);
    message_sprite.SetX(Window.GetWidth() / 2 - message_image.GetWidth() / 2);
}
Plymouth.SetMessageFunction(message_cb);
PLYMOUTH_SCRIPT

    # Create progress bar images
    # Progress box (dark background)
    convert -size 400x20 xc:'#1A1A1A' "${THEME_DIR}/progress_box.png" 2>/dev/null || \
    echo "[BRANDING] ImageMagick not available, using fallback"

    # Progress bar (Rosso Corsa)
    convert -size 400x20 xc:'#D40000' "${THEME_DIR}/progress_bar.png" 2>/dev/null || \
    echo "[BRANDING] ImageMagick not available, using fallback"

    # Copy logo if exists, otherwise create text-based placeholder
    if [ -f "/build/assets/logo.png" ]; then
        cp /build/assets/logo.png "${THEME_DIR}/logo.png"
        echo "[BRANDING] Logo copied from assets"
    else
        # Create a simple Rosso Corsa text logo
        convert -size 300x100 xc:'#0A0A0A' \
            -font DejaVu-Sans-Bold -pointsize 48 \
            -fill '#D40000' -gravity center \
            -annotate 0 "TaaOS" \
            "${THEME_DIR}/logo.png" 2>/dev/null || \
        echo "[BRANDING] Could not create logo, will use text fallback"
    fi

    # Set TaaOS as default Plymouth theme
    echo "[BRANDING] Setting TaaOS as default Plymouth theme..."
    plymouth-set-default-theme taaos || true
    update-initramfs -u || echo "[BRANDING] initramfs update deferred"

    echo "[BRANDING] Plymouth setup completed!"
}

# -----------------------------------------------------------------------------
# SECTION 2: LIGHTDM LOGIN SCREEN
# -----------------------------------------------------------------------------
setup_lightdm() {
    echo "[BRANDING] Installing LightDM..."
    apt-get install -y lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

    echo "[BRANDING] Configuring LightDM..."
    
    # Create LightDM configuration
    mkdir -p /etc/lightdm
    
    # Main LightDM config
    cat > /etc/lightdm/lightdm.conf << 'LIGHTDM_CONF'
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=xfce
greeter-hide-users=false
allow-guest=false

[LightDM]
run-directory=/run/lightdm
LIGHTDM_CONF

    # GTK Greeter configuration - Rosso Corsa theme
    cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'GTK_GREETER_CONF'
[greeter]
theme-name=Adwaita-dark
icon-theme-name=Papirus-Dark
font-name=Fira Sans 11
background=/usr/share/backgrounds/taaos/login-bg.png
user-background=false
position=50%,center 50%,center
clock-format=%H:%M | %A, %d %B
indicators=~host;~spacer;~clock;~spacer;~power
screensaver-timeout=60

[monitor: *]
background=/usr/share/backgrounds/taaos/login-bg.png
GTK_GREETER_CONF

    # Create backgrounds directory
    mkdir -p /usr/share/backgrounds/taaos

    # Create a Rosso Corsa login background
    # Check for custom wallpaper in assets
    if [ -f "/build/assets/wallpaper.png" ]; then
        echo "[BRANDING] Custom wallpaper found, copying..."
        cp "/build/assets/wallpaper.png" "/usr/share/backgrounds/taaos/login-bg.png"
    fi

    if [ ! -f "/usr/share/backgrounds/taaos/login-bg.png" ]; then
        # Create black gradient with Rosso Corsa accent
        convert -size 1920x1080 xc:'#0A0A0A' \
            -gravity center \
            -font DejaVu-Sans-Bold -pointsize 72 \
            -fill '#D4000033' \
            -annotate 0 "TaaOS" \
            /usr/share/backgrounds/taaos/login-bg.png 2>/dev/null || \
        # Fallback: solid black
        convert -size 1920x1080 xc:'#0A0A0A' \
            /usr/share/backgrounds/taaos/login-bg.png 2>/dev/null || \
        echo "[BRANDING] Could not create login background"
    fi

    # Update alternatives to use LightDM
    update-alternatives --set x-session-manager /usr/bin/xfce4-session 2>/dev/null || true

    echo "[BRANDING] LightDM setup completed!"
}

# -----------------------------------------------------------------------------
# SECTION 3: SYSTEM LOGO ASSETS
# -----------------------------------------------------------------------------
setup_system_logos() {
    echo "[BRANDING] Setting up system logo assets..."

    # Create icon directories
    mkdir -p /usr/share/icons/hicolor/256x256/apps
    mkdir -p /usr/share/icons/hicolor/128x128/apps
    mkdir -p /usr/share/icons/hicolor/64x64/apps
    mkdir -p /usr/share/icons/hicolor/48x48/apps
    mkdir -p /usr/share/pixmaps

    # Copy or create logo in various sizes
    LOGO_SOURCE="/build/assets/logo.png"
    
    if [ -f "${LOGO_SOURCE}" ]; then
        echo "[BRANDING] Processing logo from assets..."
        
        # Resize to various icon sizes
        convert "${LOGO_SOURCE}" -resize 256x256 /usr/share/icons/hicolor/256x256/apps/taaos.png 2>/dev/null || true
        convert "${LOGO_SOURCE}" -resize 128x128 /usr/share/icons/hicolor/128x128/apps/taaos.png 2>/dev/null || true
        convert "${LOGO_SOURCE}" -resize 64x64 /usr/share/icons/hicolor/64x64/apps/taaos.png 2>/dev/null || true
        convert "${LOGO_SOURCE}" -resize 48x48 /usr/share/icons/hicolor/48x48/apps/taaos.png 2>/dev/null || true
        
        # Copy to pixmaps
        cp "${LOGO_SOURCE}" /usr/share/pixmaps/taaos-logo.png
    else
        echo "[BRANDING] No logo found in assets, creating Rosso Corsa logo..."
        
        # Create Rosso Corsa text-based logo
        for size in 256 128 64 48; do
            convert -size ${size}x${size} xc:'#0A0A0A' \
                -font DejaVu-Sans-Bold -pointsize $((size/4)) \
                -fill '#D40000' -gravity center \
                -annotate 0 "T" \
                /usr/share/icons/hicolor/${size}x${size}/apps/taaos.png 2>/dev/null || true
        done
    fi

    # Update icon cache
    gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

    echo "[BRANDING] System logos setup completed!"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "[BRANDING] Starting TaaOS Visual Identity Setup..."
    echo "[BRANDING] Theme: Rosso Corsa + Black + Off-White"
    echo ""

    # Install ImageMagick for image processing
    apt-get install -y imagemagick || echo "[BRANDING] ImageMagick installation skipped"

    setup_plymouth
    echo ""
    
    setup_lightdm
    echo ""
    
    setup_system_logos
    echo ""

    echo "=============================================="
    echo "  TaaOS Branding Setup - COMPLETE!"
    echo "  Theme: Rosso Corsa (#D40000)"
    echo "=============================================="
}

# Run main function
main "$@"
