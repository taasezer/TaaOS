#!/bin/bash
# TaaOS Wallpaper Enforcer - Runs at desktop startup
# Forces the wallpaper no matter what the monitor is named

WALLPAPER="/usr/share/backgrounds/taaos/wallpaper.png"

if [ ! -f "$WALLPAPER" ]; then
    exit 0
fi

sleep 2  # Wait for xfdesktop to fully initialize

# Get real monitor name from xrandr
MONITOR=$(xrandr --listactivemonitors 2>/dev/null | awk 'NR>1 {print $NF; exit}')

if [ -z "$MONITOR" ]; then
    MONITOR="monitor0"
fi

# Force wallpaper on the detected monitor using xfconf
xfconf-query --channel xfce4-desktop \
    --property "/backdrop/screen0/${MONITOR}/workspace0/last-image" \
    --create --type string --set "$WALLPAPER" 2>/dev/null || true

xfconf-query --channel xfce4-desktop \
    --property "/backdrop/screen0/${MONITOR}/workspace0/image-style" \
    --create --type int --set 5 2>/dev/null || true

xfconf-query --channel xfce4-desktop \
    --property "/backdrop/screen0/${MONITOR}/workspace0/color-style" \
    --create --type int --set 0 2>/dev/null || true

# Restart xfdesktop to pick up changes
xfdesktop --reload 2>/dev/null || true
