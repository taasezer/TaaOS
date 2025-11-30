#!/bin/bash
#
# TaaOS Localization Setup
# Generates locales and configures system language
#

echo "Configuring TaaOS Localization..."

# Copy configuration files
cp taaos/config/locale/locale.gen /etc/locale.gen
cp taaos/config/locale/locale.conf /etc/locale.conf
cp taaos/config/locale/vconsole.conf /etc/vconsole.conf

# Generate locales
echo "Generating locales..."
locale-gen

# Set keyboard layout for X11/Wayland
echo "Setting keyboard layout..."
localectl set-x11-keymap tr

# Install language packs
echo "Installing Turkish language packs..."
taapac install \
    hunspell-tr \
    man-pages-tr \
    firefox-i18n-tr \
    libreoffice-fresh-tr \
    plasma-workspace-wallpapers \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-liberation \
    ttf-dejavu \
    terminus-font

echo "✓ Localization complete. System is now in Turkish."
