# TaaOS GUI Applications - Complete List

TaaOS now includes comprehensive GUI applications built with PyQt5, all following Arch Linux minimal design principles with Rosso Corsa theming.

## Core Applications

### 1. TaaPac GUI (`taaos/taapac/gui/taapac-gui`)
**Modern Package Manager Interface**
- ✅ Search and filter packages
- ✅ One-click install/remove
- ✅ Parallel download progress
- ✅ Dependency visualization
- ✅ Package details and descriptions
- ✅ System upgrade management
- ✅ Repository synchronization
- ✅ Installed package list
- ✅ Update notifier

**Features:**
- Rosso Corsa theme throughout
- Real-time package search
- Category filtering
- Terminal output viewer
- Backup before operations
- Transaction history

### 2. TaaOS Welcome (`taaos/desktop/welcome/taaos-welcome`)
**First-Run Experience**
- ✅ Multi-page welcome tour
- ✅ Feature showcase
- ✅ Theme selection wizard
- ✅ Quick start guide
- ✅ System customization
- ✅ "Don't show again" option

**Pages:**
1. Welcome screen with TaaOS branding
2. Features overview (8 major features)
3. Theme customization (5 themes)
4. Quick start commands

### 3. TaaOS System Monitor (`taaos/desktop/tools/taaos-monitor`)
**Real-Time System Statistics**

```python
# Features implemented:
- CPU usage (per-core and total)
- Memory usage (RAM + Swap)
- Disk I/O statistics
- Network traffic monitoring
- Process list with details
- Kill/nice processes
- Temperature sensors
- GPU usage (if available)
- Graphical charts (live updating)
```

### 4. TaaOS Control Center (`taaos/desktop/settings/taaos-control-center`)
**Unified Settings Panel**

Modules:
- **Appearance**: Themes, colors, fonts, icons
- **Display**: Resolution, refresh rate, multi-monitor
- **Network**: WiFi, Ethernet, VPN configuration
- **Users**: Account management, groups, permissions
- **Services**: Systemd service control
- **Updates**: Package update settings
- **Security**: TaaOS Guardian configuration
- **Performance**: CPU governor, I/O scheduler
- **Power**: Battery, lid action, suspend settings

### 5. TaaOS Installer (`taaos/iso/installer/taaos-installer-gui`)
**Graphical System Installer**

Steps:
1. Welcome and language selection
2. Partition editor (automatic/manual)
3. User account creation
4. Timezone and locale
5. Desktop environment selection
6. Package selection
7. Installation progress
8. Completion and reboot

**Features:**
- Automatic disk partitioning
- Manual partition editor with resize
- Btrfs snapshot setup
- GRUB bootloader installation
- Network configuration
- Mirror selection

### 6. TaaTheme Manager (`taaos/taatheme/gui/taatheme-manager`)
**Visual Theme Customization**

- ✅ Live theme preview
- ✅ Color picker for custom themes
- ✅ Export/import theme files
- ✅ Apply to all components:
  - KDE Plasma
  - Terminal (Konsole)
  - VSCode
  - GTK apps
  - Qt apps
  - GRUB bootloader
  - Plymouth splash

### 7. TaaOS Guardian GUI (`taaos/security/guardian/guardian-gui`)
**Security Monitoring Dashboard**

Panels:
- Real-time threat detection
- Memory anomaly alerts
- AppArmor profile status
- Firewall rules manager
- Security log viewer
- Vulnerability scanner
- Audit log analysis
- Security score dashboard

### 8. TaaBuild GUI (`taaos/taapac/gui/taabuild-studio`)
**Package Build Studio**

- Project wizard
- JSON editor with syntax highlighting
- Dependency resolver
- Build output viewer
- Package tester
- One-click publish to repository

### 9. TaaOS Update Manager (`taaos/desktop/tools/update-manager`)
**System Update Interface**

- Check for updates
- Download size calculator
- Changelog viewer
- Selective updates
- Update scheduling
- Automatic updates toggle
- Rollback support (btrfs snapshots)

### 10. TaaOS Terminal (`taaos/desktop/terminal/taaos-terminal`)
**Custom Terminal Emulator**

- Rosso Corsa theme by default
- Tabs and splits
- Transparency support
- Font customization
- Color schemes
- Quick commands sidebar
- SSH connection manager

## Desktop Integration

### Application Launchers
All apps include `.desktop` files in `/usr/share/applications/`:
```
taaos-taapac.desktop
taaos-welcome.desktop
taaos-settings.desktop
taaos-monitor.desktop
taaos-guardian.desktop
taaos-theme-manager.desktop
taaos-installer.desktop
```

### Systray Integration
- TaaPac update notifier
- TaaOS Guardian status icon
- System monitor (CPU/RAM quick view)
- Network manager

### Keyboard Shortcuts
```
Meta + P  →  TaaPac GUI
Meta + W  →  Welcome Screen
Meta + I  →  System Monitor
Meta + ,  →  Control Center
F12       →  TaaOS Terminal (drop-down)
```

## Additional Features

### File Manager Integration
- Right-click "Open as root"
- "Build package here" (TaaBuild)
- "Analyze disk usage"
- Custom file type associations

### Desktop Widgets (Plasma)
- CPU/Memory monitor
- Package update count
- System temperature
- Quick launch panel
- TaaOS news feed

### Login Manager Theme
Custom SDDM theme with Rosso Corsa:
```
taaos/branding/sddm/taaos-sddm/
├── theme.conf
├── Main.qml
├── Background.qml
├── Login.qml
└── assets/
    ├── logo.svg
    ├── background.jpg
    └── avatar-default.png
```

## CLI Tools with GUI Wrappers

All CLI tools have GUI counterparts:
- `taapac` → `taapac-gui`
- `taabuild` → `taabuild-studio`
- `taatheme` → `taatheme-manager`
- `taaos-guardian` → `guardian-gui`

## Technology Stack

**GUI Framework:** PyQt5
**Language:** Python 3.12+
**Theme:** Custom Rosso Corsa Qt stylesheet
**Icons:** Breeze Dark + TaaOS custom icons
**Fonts:** Inter UI, JetBrains Mono (code)

## Design Philosophy

Following Arch Linux principles:
- **Minimal**: Only essential features
- **Powerful**: Advanced options available
- **Fast**: Optimized UI  rendering
- **Transparent**: Show what's happening
- **Customizable**: Every aspect configurable

With TaaOS additions:
- **Beautiful**: Rosso Corsa theme
- **Modern**: Latest UI patterns
- **Integrated**: All tools work together
- **Developer-friendly**: Shortcuts and power features

## Building GUI Applications

```bash
# Install dependencies
sudo taapac install python-pyqt5 python-psutil python-requests

# Run individual apps
python3 taaos/taapac/gui/taapac-gui
python3 taaos/desktop/welcome/taaos-welcome
python3 taaos/desktop/settings/taaos-control-center

# Install system-wide
sudo make install-gui-apps
```

## Complete Application Count

- **10 major GUI applications**
- **15+ desktop utilities**
- **5 system tools**
- **Custom theme for all Qt/GTK apps**
- **Integrated desktop environment**

All with:
- Rosso Corsa branding
- Dark theme by default
- Minimal Arch-style design
- Full functionality
- Production-ready code

---

**TaaOS GUI Suite - Complete and Integrated** ✅
