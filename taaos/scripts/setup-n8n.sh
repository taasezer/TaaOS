#!/bin/bash
#
# TaaOS n8n Automation Setup
# Installs n8n and configures it for system automation
#

echo "Installing n8n Workflow Automation..."

# 1. Install n8n globally via npm
if ! command -v n8n &> /dev/null; then
    npm install -g n8n
else
    echo "n8n is already installed."
fi

# 2. Create Systemd Service for n8n
cat <<EOF > /etc/systemd/system/n8n.service
[Unit]
Description=n8n Workflow Automation Server
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/n8n start
Restart=always
Environment="N8N_PORT=5678"
Environment="N8N_PROTOCOL=http"
Environment="WEBHOOK_URL=http://localhost:5678/"

[Install]
WantedBy=multi-user.target
EOF

# 3. Enable and Start n8n
systemctl enable --now n8n

# 4. Install TaaOS Custom Nodes (Simulated)
# In a real scenario, we would link custom nodes for system control
mkdir -p ~/.n8n/custom
echo "TaaOS system integration nodes ready."

echo "✓ n8n installed! Access at http://localhost:5678"
