#!/bin/bash
# =============================================================================
# TaaOS Container Infrastructure Installation
# =============================================================================
# Script: install-containers.sh
# Purpose: Install Docker Engine and Portainer CE for container management
# =============================================================================

set -e

echo "=============================================="
echo "  TaaOS Container Infrastructure"
echo "=============================================="

# -----------------------------------------------------------------------------
# SECTION 1: DOCKER ENGINE INSTALLATION
# -----------------------------------------------------------------------------
install_docker() {
    echo "[CONTAINERS] Installing Docker Engine..."
    
    # Update package index
    apt-get update
    
    # Install prerequisites
    echo "[CONTAINERS] Installing Docker prerequisites..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https
    
    # Create keyrings directory
    install -m 0755 -d /etc/apt/keyrings
    
    # Add Docker's official GPG key
    echo "[CONTAINERS] Adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up the Docker repository
    echo "[CONTAINERS] Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index with Docker repo
    apt-get update
    
    # Install Docker Engine
    echo "[CONTAINERS] Installing Docker packages..."
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    
    # Enable Docker service
    systemctl enable docker || true
    systemctl enable containerd || true
    
    # Configure Docker daemon
    echo "[CONTAINERS] Configuring Docker daemon..."
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'DOCKER_DAEMON'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "features": {
        "buildkit": true
    },
    "default-address-pools": [
        {
            "base": "172.17.0.0/16",
            "size": 24
        }
    ],
    "dns": ["8.8.8.8", "8.8.4.4"],
    "live-restore": true,
    "userland-proxy": false
}
DOCKER_DAEMON

    # Add default user to docker group
    echo "[CONTAINERS] Adding engineer user to docker group..."
    usermod -aG docker engineer 2>/dev/null || true
    
    # Create docker completion
    cat >> /etc/bash.bashrc << 'DOCKER_COMPLETION'

# Docker command completion
if command -v docker &> /dev/null; then
    eval "$(docker completion bash 2>/dev/null)" || true
fi
DOCKER_COMPLETION

    echo "[CONTAINERS] Docker Engine installed successfully!"
}

# -----------------------------------------------------------------------------
# SECTION 2: PORTAINER CE INSTALLATION
# -----------------------------------------------------------------------------
install_portainer() {
    echo "[CONTAINERS] Installing Portainer CE..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "[CONTAINERS] ERROR: Docker is required for Portainer"
        return 1
    fi
    
    # Create Portainer data volume
    docker volume create portainer_data 2>/dev/null || true
    
    # Pull Portainer CE image
    echo "[CONTAINERS] Pulling Portainer CE image..."
    docker pull portainer/portainer-ce:latest || echo "[CONTAINERS] Will pull Portainer on first boot"
    
    # Create Portainer systemd service
    echo "[CONTAINERS] Creating Portainer service..."
    cat > /etc/systemd/system/portainer.service << 'PORTAINER_SERVICE'
[Unit]
Description=Portainer Container Management
Documentation=https://docs.portainer.io
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/bin/docker stop portainer
ExecStartPre=-/usr/bin/docker rm portainer
ExecStart=/usr/bin/docker run -d \
    --name portainer \
    --restart=always \
    -p 9000:9000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
ExecStop=/usr/bin/docker stop portainer

[Install]
WantedBy=multi-user.target
PORTAINER_SERVICE

    # Enable Portainer service
    systemctl enable portainer || true
    
    # Create startup script for first boot
    cat > /usr/local/bin/start-portainer << 'PORTAINER_SCRIPT'
#!/bin/bash
# Start Portainer CE container

# Check if running
if docker ps | grep -q portainer; then
    echo "Portainer is already running"
    echo "Access at: http://localhost:9000 or https://localhost:9443"
    exit 0
fi

# Pull latest if not available
docker pull portainer/portainer-ce:latest 2>/dev/null || true

# Remove old container if exists
docker stop portainer 2>/dev/null || true
docker rm portainer 2>/dev/null || true

# Start Portainer
docker run -d \
    --name portainer \
    --restart=always \
    -p 9000:9000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest

echo ""
echo "Portainer CE is running!"
echo "Access at: http://localhost:9000"
echo "Secure access: https://localhost:9443"
PORTAINER_SCRIPT

    chmod +x /usr/local/bin/start-portainer
    
    # Create desktop entry
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/portainer.desktop << 'PORTAINER_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Portainer
Comment=Container Management Platform
Icon=docker
Exec=xdg-open http://localhost:9000
Categories=Development;System;
Terminal=false
PORTAINER_DESKTOP

    echo "[CONTAINERS] Portainer CE configured!"
    echo "[CONTAINERS] Access at http://localhost:9000 after boot"
}

# -----------------------------------------------------------------------------
# SECTION 3: ADDITIONAL CONTAINER TOOLS
# -----------------------------------------------------------------------------
install_container_tools() {
    echo "[CONTAINERS] Installing additional container tools..."
    
    # Docker Compose (standalone, for compatibility)
    echo "[CONTAINERS] Installing Docker Compose standalone..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K[^"]+' 2>/dev/null || echo "v2.24.0")
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
        -o /usr/local/bin/docker-compose 2>/dev/null || echo "[CONTAINERS] docker-compose download skipped"
    chmod +x /usr/local/bin/docker-compose 2>/dev/null || true
    
    # Lazydocker - Terminal UI for Docker
    echo "[CONTAINERS] Installing Lazydocker..."
    curl -sL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>/dev/null || echo "[CONTAINERS] Lazydocker installation skipped"
    
    # ctop - Top for containers
    echo "[CONTAINERS] Installing ctop..."
    curl -Lo /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 2>/dev/null || echo "[CONTAINERS] ctop download skipped"
    chmod +x /usr/local/bin/ctop 2>/dev/null || true
    
    # Dive - Docker image explorer
    DIVE_VERSION="0.11.0"
    curl -Lo /tmp/dive.deb "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb" 2>/dev/null && \
        dpkg -i /tmp/dive.deb 2>/dev/null || echo "[CONTAINERS] Dive installation skipped"
    rm -f /tmp/dive.deb
    
    # Add useful aliases
    cat >> /etc/bash.bashrc << 'CONTAINER_ALIASES'

# Container management aliases
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"'
alias dlog='docker logs -f'
alias dexec='docker exec -it'
alias dclean='docker system prune -af --volumes'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
CONTAINER_ALIASES

    echo "[CONTAINERS] Additional container tools installed!"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "[CONTAINERS] Starting Container Infrastructure Setup..."
    echo ""

    install_docker
    echo ""
    
    install_portainer
    echo ""
    
    install_container_tools
    echo ""

    echo "=============================================="
    echo "  Container Infrastructure - COMPLETE!"
    echo "=============================================="
    echo ""
    echo "  Installed Components:"
    echo "  - Docker Engine CE (with BuildKit)"
    echo "  - Docker Compose v2"
    echo "  - Portainer CE (port 9000/9443)"
    echo "  - Lazydocker, ctop, dive"
    echo ""
    echo "  Commands:"
    echo "  - docker, docker compose"
    echo "  - start-portainer (manual start)"
    echo "  - dps, dclean, dc (aliases)"
    echo ""
}

# Run main function
main "$@"
