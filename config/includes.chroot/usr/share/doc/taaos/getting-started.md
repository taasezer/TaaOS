# Getting Started with TaaOS

Welcome to TaaOS - a developer-focused Linux distribution based on Debian 12.

## First Steps

### 1. Choose Your Installation Mode

After booting TaaOS, select your preferred mode:

- **Live Mode**: Run directly from USB without changes
- **Persistent Live**: Keep changes across reboots
- **Full Installation**: Install to disk using Calamares

```bash
# For persistence setup:
sudo taaos-setup-persistence
```

### 2. Update Your System

```bash
taaos-update check
taaos-update now    # If updates available
```

### 3. Install Development Tools

Choose a category based on your needs:

```bash
# AI/Machine Learning
taaos-pkg install ai-ml

# Web Development
taaos-pkg install webdev

# System Programming
taaos-pkg install sysdev

# DevOps Tools
taaos-pkg install devops
```

### 4. Configure Your Environment

```bash
taaos-config
# Select [3] Development Environment
```

This helps you set up:
- Git username and email
- SSH keys for GitHub/GitLab
- VS Code settings
- Default editor

### 5. Hardware Detection

```bash
sudo taaos-drivers detect
```

Automatically configures:
- GPU drivers (NVIDIA, AMD, Intel)
- WiFi firmware
- Bluetooth
- Touchpad settings

## Essential Commands

| Command | Description |
|---------|-------------|
| `taaos-pkg` | Package management |
| `taaos-update` | System updates |
| `taaos-config` | System settings |
| `taaos-drivers` | Hardware setup |
| `taaos-rescue` | Recovery tools |
| `taaos-help` | Documentation |

## Getting Help

```bash
taaos-help              # Interactive help
taaos-help trouble      # Troubleshooting
man <command>           # Manual pages
```

## Report Issues

GitHub: https://github.com/taasezer/TaaOS/issues
