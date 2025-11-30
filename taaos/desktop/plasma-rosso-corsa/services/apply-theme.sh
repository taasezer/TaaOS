#!/bin/bash
#
# TaaOS Plasma Service
# Applies Rosso Corsa theme to Plasma desktop
#

# Wait for Plasma to start
sleep 5

# Apply color scheme
kwriteconfig5 --file kdeglobals --group General --key ColorScheme RossoCorsa

# Apply window decoration
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme Breeze

# Apply icon theme
kwriteconfig5 --file kdeglobals --group Icons --key Theme TaaOS-Icons

# Apply cursor theme
kwriteconfig5 --file kcminputrc --group Mouse --key cursorTheme TaaOS-Cursors

# Restart Plasma
kquitapp5 plasmashell && kstart5 plasmashell
