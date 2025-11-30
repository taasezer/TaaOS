#!/bin/bash
#
# TaaOS Directory Structure Fixer
# Ensures all tools are in the right place and executable
#

echo "Organizing TaaOS file structure..."

# Create bin directory
mkdir -p taaos/bin

# List of tools to link
TOOLS=(
    "taaos/desktop/tools/taaos-monitor"
    "taaos/desktop/tools/taaos-cleanup"
    "taaos/desktop/tools/taaos-info"
    "taaos/desktop/tools/taaos-backup"
    "taaos/desktop/tools/taaos-services"
    "taaos/desktop/tools/taaos-logs"
    "taaos/desktop/tools/taaos-disk-manager"
    "taaos/desktop/tools/taaos-cloud-sync"
    "taaos/desktop/tools/taaos-mobile-manager"
    "taaos/desktop/tools/taaos-hardware-detect"
    "taaos/desktop/tools/taaos-benchmark"
    "taaos/desktop/tools/taaos-docker-manager"
    "taaos/desktop/tools/taaos-gaming-center"
    "taaos/desktop/tools/taaos-system-repair"
    "taaos/desktop/tools/taaos-network-manager"
    "taaos/desktop/tools/taaos-office-integration"
    "taaos/desktop/tools/taaos-update-manager"
    "taaos/desktop/tools/taaos-firewall-manager"
    "taaos/desktop/tools/taaos-boot-manager"
    "taaos/desktop/settings/taaos-control-center"
    "taaos/iso/installer/taaos-installer-gui"
    "taaos/taapac/gui/taapac-gui"
)

for tool in "${TOOLS[@]}"; do
    if [ -f "$tool" ]; then
        # Make executable
        chmod +x "$tool"
        
        # Create symlink in bin
        basename=$(basename "$tool")
        ln -sf "../$tool" "taaos/bin/$basename"
        echo "✓ Linked $basename"
    else
        echo "⚠ Warning: $tool not found"
    fi
done

echo "File structure organization complete."
