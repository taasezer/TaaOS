#!/bin/bash
# =============================================================================
# TaaOS Help System
# =============================================================================
# Interactive documentation and troubleshooting guide
# =============================================================================

set -euo pipefail

DOCS_DIR="/usr/share/doc/taaos"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# MENU
# =============================================================================
show_menu() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   TaaOS Help System                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  [1] Getting Started"
    echo "  [2] Package Management"
    echo "  [3] Development Tools"
    echo "  [4] Docker & Containers"
    echo "  [5] System Administration"
    echo "  [6] Troubleshooting"
    echo "  [7] TaaOS Commands"
    echo "  [8] TaaOS AI Assistant"
    echo "  [9] FAQ"
    echo "  [0] Search Documentation"
    echo "  [q] Exit"
    echo ""
    read -p "Select topic: " choice
    echo "$choice"
}

# =============================================================================
# TOPICS
# =============================================================================
show_getting_started() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  GETTING STARTED WITH TaaOS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [[ -f "$DOCS_DIR/getting-started.md" ]]; then
        less "$DOCS_DIR/getting-started.md"
    else
        cat << 'EOF'
# Getting Started with TaaOS

## 1. First Boot
After booting TaaOS, you can choose between:
- **Live Mode**: Run directly from USB/DVD
- **Persistent Mode**: Keep your changes across reboots
- **Full Installation**: Install to disk via Calamares

## 2. Check for Updates
```bash
taaos-update check
```

## 3. Install Development Stacks
```bash
taaos-pkg install ai-ml      # AI/ML tools
taaos-pkg install webdev     # Web development
taaos-pkg install sysdev     # System programming
taaos-pkg install devops     # DevOps tools
```

## 4. Configure Your System
```bash
taaos-config                  # System settings
taaos-drivers                 # Hardware detection
```

## 5. Get Help
```bash
taaos-help                    # This help system
man <command>                 # Manual pages
```
EOF
    fi
}

show_package_management() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  PACKAGE MANAGEMENT${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat << 'EOF'
# TaaOS Package Manager (taaos-pkg)

## Basic Commands
```bash
taaos-pkg install <package>   # Install package
taaos-pkg remove <package>    # Remove package
taaos-pkg update              # Update package lists
taaos-pkg upgrade             # Upgrade all packages
taaos-pkg search <query>      # Search packages
```

## Category Installation
Install complete development stacks:
```bash
taaos-pkg install ai-ml           # TensorFlow, PyTorch, Jupyter
taaos-pkg install devops          # Docker, Kubernetes, Terraform
taaos-pkg install webdev          # Node.js, databases, frameworks
taaos-pkg install sysdev          # GCC, Rust, debugging tools
taaos-pkg install data-science    # Pandas, R, visualization
taaos-pkg install virtualization  # KVM, QEMU, Virt-Manager
```

## View Categories
```bash
taaos-pkg category     # List all categories
```
EOF
}

show_development() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  DEVELOPMENT TOOLS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat << 'EOF'
# Development Environment

## Setup via taaos-config
```bash
taaos-config
# Select [3] Development Environment
```

This helps you:
- Configure Git (username, email)
- Generate SSH keys for GitHub/GitLab
- Setup VS Code settings
- Set default editor

## Available Stacks

### AI/ML Development
```bash
taaos-pkg install ai-ml
# Includes: Python, Jupyter, TensorFlow, PyTorch
```

### Web Development
```bash
taaos-pkg install webdev
# Includes: Node.js, npm, PostgreSQL, Redis
```

### System Programming
```bash
taaos-pkg install sysdev
# Includes: GCC, Clang, Rust, GDB, Valgrind
```

## IDE Options
- VS Code: `taaos-pkg install code`
- JetBrains: Install via Toolbox
- Vim/Neovim: Pre-installed
EOF
}

show_docker() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  DOCKER & CONTAINERS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat << 'EOF'
# Docker on TaaOS

## Enable Docker
```bash
taaos-config
# Select [4] Services → Docker
# Or:
sudo systemctl enable --now docker
```

## Common Commands
```bash
docker ps                     # List running containers
docker ps -a                  # List all containers
docker images                 # List images
docker run -it ubuntu bash    # Run interactive container
docker-compose up -d          # Start compose services
```

## Add User to Docker Group
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

## Useful Tools
- **Portainer**: Web UI for Docker
- **ctop**: Top for containers
- **dive**: Analyze image layers
EOF
}

show_sysadmin() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  SYSTEM ADMINISTRATION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat << 'EOF'
# System Administration

## TaaOS Tools
```bash
taaos-config      # System settings
taaos-update      # System updates
taaos-rescue      # Recovery options
taaos-drivers     # Hardware detection
taaos-health-check # System health
```

## Service Management
```bash
systemctl status <service>    # Check status
systemctl start <service>     # Start service
systemctl enable <service>    # Enable at boot
systemctl restart <service>   # Restart service
```

## Disk Management
```bash
df -h             # Disk usage
lsblk             # Block devices
fdisk -l          # Partition info
```

## Network
```bash
ip addr           # IP addresses
nmtui             # Network Manager TUI
ss -tulpn         # Open ports
```
EOF
}

show_troubleshooting() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  TROUBLESHOOTING${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat << 'EOF'
# Common Issues & Solutions

## Boot Problems
**Black screen after boot:**
1. At GRUB menu, press 'e' to edit
2. Add 'nomodeset' to kernel line
3. Press Ctrl+X to boot

**Secure Boot issues:**
- Disable Secure Boot in BIOS

## WiFi Not Working
```bash
sudo taaos-drivers wifi
# Or install firmware manually:
sudo apt install firmware-iwlwifi
```

## Display Issues
**Wrong resolution:**
```bash
xrandr --output HDMI-1 --mode 1920x1080
# Or use:
taaos-config → Display Settings
```

## Package Issues
**Broken packages:**
```bash
sudo taaos-rescue
# Select [3] Repair Package Database
```

## System Recovery
```bash
sudo taaos-rescue
# Options: Snapshot, Restore, Repair, Backup
```

## Logs
```bash
journalctl -xe           # System logs
cat /var/log/taaos/*.log # TaaOS logs
dmesg | tail             # Kernel messages
```
EOF
}

show_commands() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  TAAOS COMMANDS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat << 'EOF'
# TaaOS Command Reference

## Package Management
  taaos-pkg install <pkg>     Install package or category
  taaos-pkg remove <pkg>      Remove package
  taaos-pkg update            Update package lists
  taaos-pkg upgrade           Upgrade all packages
  taaos-pkg search <query>    Search packages
  taaos-pkg category          Show categories

## System Updates
  taaos-update check          Check for updates
  taaos-update now            Install updates
  taaos-update rollback       Rollback via Timeshift
  taaos-update status         Show version

## Configuration
  taaos-config                System settings menu
  taaos-drivers               Hardware detection
  taaos-drivers status        Show hardware

## Recovery
  taaos-rescue                Recovery menu
  taaos-health-check          System health

## AI Assistant (TaaNOS)
  taanos                      Start TaaNOS AI Assistant
  taanos init                 First-time model setup
  natural                     Alias for taanos

## Help
  taaos-help                  This help system
EOF
}

show_natural_engine() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  TAAOS AI ASSISTANT (TaaNOS)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat << 'EOF'
# TaaNOS — Natural Engine

TaaOS comes with TaaNOS, a deterministic AI-powered CLI system.
Unlike standard AI assistants, TaaNOS uses AI only for intent
extraction and relies on a hardcoded, safe action registry.

## First-Time Setup
```bash
taanos init                   # Configure Ollama + select model
```

## Basic Usage
Type what you want to do in plain English (or Turkish):
```bash
taanos install nginx
taanos "açık portları listele"
natural "show me my large files"   # alias for taanos
```

## Execution Modes
```bash
taanos -m explain install nginx    # Show plan without executing
taanos -m auto install nginx       # Auto-execute after confirmation
taanos -m guided install nginx     # Step-by-step (default)
```

## Commands
```bash
taanos status                 # View system & AI status
taanos history                # Show past operations
taanos model                  # View or change AI model
taanos config                 # Show configuration
taanos version                # Show version info
```
EOF
}

show_faq() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  FREQUENTLY ASKED QUESTIONS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat << 'EOF'
# FAQ

## Q: What is TaaOS based on?
A: TaaOS is based on Debian 12 (Bookworm) with a custom kernel
   optimized for development and containerization.

## Q: How do I install software?
A: Use taaos-pkg for packages and categories:
   taaos-pkg install <package>
   taaos-pkg install ai-ml  (category)

## Q: How do I update the system?
A: Run: taaos-update check
   Then: taaos-update now

## Q: How do I create a backup?
A: Use Timeshift via taaos-rescue:
   sudo taaos-rescue → Create Snapshot

## Q: Where are TaaOS logs?
A: /var/log/taaos/

## Q: How do I report issues?
A: GitHub: https://github.com/taasezer/TaaOS/issues
EOF
}

search_docs() {
    echo ""
    read -p "Search query: " query
    echo ""
    
    if [[ -d "$DOCS_DIR" ]]; then
        echo -e "${BLUE}Searching in $DOCS_DIR...${NC}"
        grep -rn --color=auto "$query" "$DOCS_DIR/" 2>/dev/null || echo "No results found"
    else
        echo "Searching in help topics..."
        # Search inline help
        script_content=$(cat "$0")
        echo "$script_content" | grep -i --color=auto "$query" || echo "No results found"
    fi
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    while true; do
        choice=$(show_menu)
        
        clear
        
        case "$choice" in
            1) show_getting_started ;;
            2) show_package_management ;;
            3) show_development ;;
            4) show_docker ;;
            5) show_sysadmin ;;
            6) show_troubleshooting ;;
            7) show_commands ;;
            8) show_natural_engine ;;
            9) show_faq ;;
            0) search_docs ;;
            q|Q|"") break ;;
            *) echo "Invalid option" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
    
    clear
    echo "Thank you for using TaaOS Help!"
}

# Quick topic access
if [[ "${1:-}" != "" ]]; then
    case "$1" in
        start|getting-started) show_getting_started ;;
        pkg|package*) show_package_management ;;
        dev|development) show_development ;;
        docker|container*) show_docker ;;
        sys|admin|sysadmin) show_sysadmin ;;
        trouble*|fix) show_troubleshooting ;;
        cmd|command*) show_commands ;;
        faq) show_faq ;;
        ai|natural|natural-engine|taanos) show_natural_engine ;;
        search) shift; search_docs "$@" ;;
        --help|-h) 
            echo "Usage: taaos-help [topic]"
            echo "Topics: start, pkg, dev, docker, sys, trouble, cmd, ai, faq, search"
            ;;
        *) main ;;
    esac
else
    main
fi
