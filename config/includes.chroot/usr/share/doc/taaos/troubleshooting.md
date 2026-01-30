# TaaOS Troubleshooting Guide

## Boot Problems

### Black Screen After Boot
1. At GRUB menu, press `e` to edit
2. Find the line starting with `linux`
3. Add `nomodeset` before `quiet`
4. Press `Ctrl+X` to boot

### Secure Boot Issues
- Enter BIOS/UEFI settings (usually F2, F12, or Del)
- Disable Secure Boot
- Save and restart

### GRUB Not Showing
```bash
sudo taaos-rescue
# Select [4] Boot Repair
```

## WiFi Issues

### WiFi Not Detected
```bash
sudo taaos-drivers wifi
# Or manually:
sudo apt install firmware-iwlwifi firmware-realtek
```

### WiFi Connects But No Internet
```bash
# Check DNS
ping 8.8.8.8
# If ping works, DNS issue:
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

## Display Problems

### Wrong Resolution
```bash
# List available modes
xrandr

# Set resolution
xrandr --output HDMI-1 --mode 1920x1080

# Or use config tool
taaos-config
# Select [1] Display Settings
```

### No Display Output
Boot with `nomodeset` parameter and install proper drivers:
```bash
sudo taaos-drivers nvidia  # For NVIDIA
sudo taaos-drivers         # Auto-detect
```

## Package Issues

### Broken Packages
```bash
sudo taaos-rescue
# Select [3] Repair Package Database
```

### Manual Fix
```bash
sudo dpkg --configure -a
sudo apt-get install -f
sudo apt-get update
```

## System Recovery

### Create Backup
```bash
sudo taaos-rescue
# Select [1] Create Snapshot
```

### Restore from Backup
```bash
sudo taaos-rescue
# Select [2] Restore from Snapshot
```

## Logs

### View System Logs
```bash
journalctl -xe              # Recent errors
journalctl -b               # Current boot
dmesg | tail -50            # Kernel messages
```

### TaaOS Logs
```bash
ls /var/log/taaos/
cat /var/log/taaos/update.log
```

## Getting Help

- `taaos-help` - Interactive documentation
- GitHub Issues: https://github.com/taasezer/TaaOS/issues
