#!/bin/bash
#
# TaaOS First Boot Script
# Runs once on the first boot to finalize configuration
#

# Check if already ran
if [ -f /var/lib/taaos/firstboot_done ]; then
    exit 0
fi

echo "Initializing TaaOS..."

# 1. Apply Localization
/usr/bin/taaos-setup-locale

# 2. Setup Developer Environment
/usr/bin/taaos-setup-dev-env

# 3. Setup AI & Automation (The "Brain" of the OS)
echo "Initializing Neural Engine & AI..."
/usr/bin/taaos-setup-ai
/usr/bin/taaos-setup-n8n

# 3.5. Install Language Packages
echo "Installing development libraries..."
# Python packages
pip3 install --user -r /usr/share/taaos/python-requirements.txt

# Node.js packages (global)
npm install -g typescript ts-node eslint prettier jest nodemon pm2

# Rust crates (common ones)
cargo install cargo-watch cargo-edit ripgrep fd-find bat

# Import n8n workflows
echo "Importing n8n workflows..."
for workflow in /usr/share/taaos/n8n-workflows/*.json; do
    curl -X POST http://localhost:5678/api/v1/workflows \
        -H "Content-Type: application/json" \
        -d @"$workflow" 2>/dev/null || true
done

# 4. Apply Theme System-wide
taatheme apply rosso-corsa

# 5. Enable All Services (Zero-Touch Config)
echo "Enabling System Services..."
SERVICES=(
    "taaos-guardian"       # Security
    "taaos-neural-engine"  # AI Core
    "taaos-brain"          # Proactive AI
    "taaos-watchdog"       # Self-Healing
    "n8n"                  # Automation
    "ollama"               # Local LLM
    "docker"               # Containers
    "bluetooth"            # Hardware
    "NetworkManager"       # Network
    "ufw"                  # Firewall
)

for service in "${SERVICES[@]}"; do
    systemctl enable --now "$service"
done

# 6. Update Search Index
updatedb

# Mark as done
mkdir -p /var/lib/taaos
touch /var/lib/taaos/firstboot_done

# Launch Welcome App for the user
cp /usr/share/applications/taaos-welcome.desktop /etc/xdg/autostart/

echo "TaaOS Initialization Complete! System is ALIVE."
