#!/bin/bash
# TaaOS Wallpaper Enforcer — Sets dark Rosso Corsa wallpaper on all monitors
WALLPAPER="/usr/share/backgrounds/taaos/wallpaper.png"

if [ ! -f "$WALLPAPER" ]; then
    exit 0
fi

sleep 1

# 1. Update every existing backdrop image property in xfconf
for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "last-image"); do
    xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER" 2>/dev/null || true
done

# 2. Also set explicitly for active monitors detected by xrandr
if command -v xrandr >/dev/null 2>&1; then
    while read -r m; do
        [ -z "$m" ] && continue
        for p in "monitor${m}" "${m}"; do
            xfconf-query -c xfce4-desktop -p "/backdrop/screen0/${p}/workspace0/last-image" --create -t string -s "$WALLPAPER" 2>/dev/null || true
            xfconf-query -c xfce4-desktop -p "/backdrop/screen0/${p}/workspace0/image-style" --create -t int -s 5 2>/dev/null || true
            xfconf-query -c xfce4-desktop -p "/backdrop/screen0/${p}/workspace0/color-style" --create -t int -s 0 2>/dev/null || true
        done
    done < <(xrandr --listactivemonitors 2>/dev/null | awk 'NR>1 {print $NF}')
fi

# 3. Fallback monitor0
xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor0/workspace0/last-image" --create -t string -s "$WALLPAPER" 2>/dev/null || true
xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor0/workspace0/image-style" --create -t int -s 5 2>/dev/null || true

# Reload xfdesktop
xfdesktop --reload 2>/dev/null || true
