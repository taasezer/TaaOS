#!/bin/bash
#
# TaaOS Wallpaper Generator
# Creates Rosso Corsa themed wallpapers
#

RESOLUTION="3840x2160"
BG_COLOR="#0A0A0A"
PRIMARY_COLOR="#D40000"
TEXT_COLOR="#F5F5F0"

# Default wallpaper - Abstract geometric
convert -size $RESOLUTION xc:"$BG_COLOR" \
    -fill "$PRIMARY_COLOR" \
    -draw "polygon 0,0 1920,0 0,1080" \
    -draw "polygon 3840,2160 1920,2160 3840,1080" \
    -blur 0x50 \
    taaos-default.png

# Dark variant
convert -size $RESOLUTION xc:"$BG_COLOR" \
    -fill "$PRIMARY_COLOR" \
    -draw "circle 1920,1080 1920,500" \
    -blur 0x100 \
    taaos-dark.png

# Minimal logo
convert -size $RESOLUTION xc:"$BG_COLOR" \
    -gravity center \
    -fill "$PRIMARY_COLOR" \
    -font "Sans-Bold" \
    -pointsize 200 \
    -annotate +0+0 "TaaOS" \
    taaos-minimal.png

echo "Wallpapers generated successfully!"
