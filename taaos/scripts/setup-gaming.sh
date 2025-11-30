#!/bin/bash
#
# TaaOS Gaming Setup Script
# Installs and configures everything needed for gaming
#

echo "Configuring TaaOS Gaming Subsystem..."

# 1. Install Gaming Packages
echo "Installing gaming packages..."
taapac install \
    steam \
    lutris \
    heroic-games-launcher-bin \
    gamemode \
    lib32-gamemode \
    mangohud \
    lib32-mangohud \
    wine-staging \
    winetricks \
    vulkan-tools \
    mesa-utils

# 2. Configure GameMode
echo "Configuring GameMode..."
mkdir -p ~/.config/gamemode.ini
cp taaos/config/gamemode.ini ~/.config/gamemode.ini

# 3. Configure Steam
echo "Configuring Steam..."
# Enable Proton for all games
mkdir -p ~/.steam/root/config
echo '"InstallConfigStore"
{
    "Software"
    {
        "Valve"
        {
            "Steam"
            {
                "ToolMapping"
                {
                    "0"
                    {
                        "name"      "proton_experimental"
                        "config"    ""
                        "priority"  "250"
                    }
                }
            }
        }
    }
}' > ~/.steam/root/config/config.vdf

# 4. Optimize Wine
echo "Optimizing Wine..."
winetricks -q dxvk vkd3d

echo "✓ Gaming setup complete! Ready to play."
