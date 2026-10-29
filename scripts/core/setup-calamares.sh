#!/bin/bash
# =============================================================================
# TaaOS Calamares Installer Configuration
# =============================================================================
# Script: setup-calamares.sh
# Purpose: Install and configure Calamares graphical installer
# =============================================================================

# NOTE: Do NOT use 'set -e' here! If apt fails, we still MUST write config files.
# Otherwise the system gets Debian default branding instead of TaaOS.

echo "=============================================="
echo "  TaaOS Calamares Installer Setup"
echo "=============================================="

# -----------------------------------------------------------------------------
# SECTION 1: CALAMARES INSTALLATION
# -----------------------------------------------------------------------------
install_calamares() {
    echo "[INSTALLER] Installing Calamares..."
    
    apt-get update || true
    
    # Install Calamares and dependencies
    apt-get install -y \
        calamares \
        calamares-settings-debian \
        qml-module-qtquick2 \
        qml-module-qtquick-controls \
        qml-module-qtquick-controls2 \
        qml-module-qtquick-layouts \
        qml-module-qtquick-window2 || echo "[INSTALLER] WARNING: Some Calamares packages may not have installed"
    
    # Install additional partitioning tools
    apt-get install -y \
        kpmcore \
        os-prober \
        squashfs-tools \
        rsync
    
    echo "[INSTALLER] Calamares installed"
}

# -----------------------------------------------------------------------------
# SECTION 2: CALAMARES CONFIGURATION
# -----------------------------------------------------------------------------
configure_calamares() {
    echo "[INSTALLER] Configuring Calamares..."
    
    # Create configuration directories
    mkdir -p /etc/calamares
    mkdir -p /etc/calamares/modules
    mkdir -p /etc/calamares/branding/taaos
    
    # Main settings.conf
    cat > /etc/calamares/settings.conf << 'CALAMARES_SETTINGS'
# =============================================================================
# TaaOS Calamares Settings
# =============================================================================
# Main configuration for the TaaOS installer
# =============================================================================

modules-search: [ local, /usr/lib/calamares/modules ]

# Execution sequence
sequence:
  - show:
    - welcome
    - locale
    - keyboard
    - partition
    - users
    - summary
  - exec:
    - partition
    - mount
    - unpackfs
    - machineid
    - fstab
    - locale
    - keyboard
    - localecfg
    - luksbootkeyfile
    - users
    - displaymanager
    - networkcfg
    - hwclock
    - packages
    - initramfscfg
    - initramfs
    - grubcfg
    - bootloader
    - shellprocess
    - umount
  - show:
    - finished

# Branding component
branding: taaos

# Prompt before installation
prompt-install: true

# Don't require restart (live system)
dont-chroot: false

# OEM mode (disabled)
oem-setup: false

# Disable cancel button during installation
disable-cancel: false

# Disable cancel on finished page
disable-cancel-during-exec: true

# Hide back button on first page
hide-back-and-next-during-exec: true

# Sidebar visibility
sidebar: true
CALAMARES_SETTINGS

    echo "[INSTALLER] Main settings configured"
}

# -----------------------------------------------------------------------------
# SECTION 3: MODULE CONFIGURATIONS
# -----------------------------------------------------------------------------
configure_modules() {
    echo "[INSTALLER] Configuring installer modules..."
    
    # Welcome module
    cat > /etc/calamares/modules/welcome.conf << 'WELCOME_CONF'
# TaaOS Welcome Module
showSupportUrl: true
showKnownIssuesUrl: true
showReleaseNotesUrl: false

requirements:
    requiredStorage: 5.5
    requiredRam: 1.0
    internetCheckUrl: https://deb.debian.org
    check:
        - storage
        - ram
        - root
    required:
        - ram

geoip:
    style: "none"
WELCOME_CONF

    # Locale module
    cat > /etc/calamares/modules/locale.conf << 'LOCALE_CONF'
# TaaOS Locale Module
region: "Europe"
zone: "Istanbul"
localeGenPath: /etc/locale.gen
geoip:
    style: "none"
LOCALE_CONF

    # Keyboard module
    cat > /etc/calamares/modules/keyboard.conf << 'KEYBOARD_CONF'
# TaaOS Keyboard Module
xOrgConfFileName: /etc/X11/xorg.conf.d/00-keyboard.conf
convertedKeymapPath: /lib/kbd/keymaps/xkb
writeEtcDefaultKeyboard: true
KEYBOARD_CONF

    # Partition module
    cat > /etc/calamares/modules/partition.conf << 'PARTITION_CONF'
# TaaOS Partition Module
efiSystemPartition: "/boot/efi"
efiSystemPartitionSize: 512M
efiSystemPartitionName: EFI

userSwapChoices:
    - none
    - small
    - suspend
    - file

drawNestedPartitions: false
alwaysShowPartitionLabels: true
allowManualPartitioning: true

initialPartitioningChoice: erase
initialSwapChoice: small

defaultFileSystemType: "ext4"
availableFileSystemTypes: ["ext4", "btrfs", "xfs"]
PARTITION_CONF

    # Users module
    cat > /etc/calamares/modules/users.conf << 'USERS_CONF'
# TaaOS Users Module
defaultGroups:
    - users
    - sudo
    - cdrom
    - floppy
    - audio
    - video
    - plugdev
    - netdev
    - lpadmin
    - scanner
    - docker
    - libvirt
    - kvm

autologinGroup: autologin

doAutologin: false

sudoersGroup: sudo

setRootPassword: true
doReusePassword: true

passwordRequirements:
    minLength: 1
    maxLength: -1
    libpwquality:
        - minlen=1

allowWeakPasswords: true
allowWeakPasswordsDefault: true

userShell: /bin/bash

hostname:
    location: EtcFile
    writeHostsFile: true
    template: "taaos-${cpu}"
    forbidden_names: [ localhost ]
USERS_CONF

    # Bootloader module
    cat > /etc/calamares/modules/bootloader.conf << 'BOOTLOADER_CONF'
# TaaOS Bootloader Module
efiBootLoader: "grub"
kernel: "/vmlinuz"
img: "/initrd.img"
kernelLine: ", with TaaOS Custom Kernel"
fallbackKernelLine: ", with TaaOS (fallback)"

grubInstall: "grub-install"
grubMkconfig: "grub-mkconfig"
grubCfg: "/boot/grub/grub.cfg"
grubProbe: "grub-probe"

efiBootloaderId: "taaos"

timeout: 5
installEFIFallback: true
BOOTLOADER_CONF

    # Finished module
    cat > /etc/calamares/modules/finished.conf << 'FINISHED_CONF'
# TaaOS Finished Module
restartNowEnabled: true
restartNowChecked: true
restartNowCommand: "/sbin/reboot"
notifyOnFinished: true
FINISHED_CONF

    # Display manager module
    cat > /etc/calamares/modules/displaymanager.conf << 'DM_CONF'
# TaaOS Display Manager Module
displaymanagers:
    - lightdm
    - gdm
    - sddm

defaultDesktopEnvironment:
    executable: "startxfce4"
    desktopFile: "xfce"

basicSetup: false
DM_CONF

    # LocaleCfg module - writes /etc/locale.conf on the installed system
    cat > /etc/calamares/modules/localecfg.conf << 'LOCALECFG_CONF'
# TaaOS LocaleCfg Module
# Writes the selected locale to the target system
localeGenPath: /etc/locale.gen
LOCALECFG_CONF

    # Hwclock module - applies timezone to the installed system
    cat > /etc/calamares/modules/hwclock.conf << 'HWCLOCK_CONF'
# TaaOS Hwclock Module
kernelUtc: true
HWCLOCK_CONF

    # Machine ID module — Systemd-Free safe
    cat > /etc/calamares/modules/machineid.conf << 'MACHINEID_CONF'
---
systemd: "systemd-style"
dbus: true
symlink: true
dbus-symlink: true
entropy-copy: false
MACHINEID_CONF

    # Systemd-machine-id-setup compatibility wrapper
    cat > /usr/bin/systemd-machine-id-setup << 'MACHINEID_SETUP'
#!/bin/sh
set -e
ROOT=""
PRINT_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --root=*) ROOT="${arg#--root=}" ;;
        --print) PRINT_ONLY=1 ;;
    esac
done
TARGET_DIR="${ROOT}/etc"
TARGET_FILE="${TARGET_DIR}/machine-id"
if [ "$PRINT_ONLY" -eq 1 ] && [ -s "$TARGET_FILE" ] && [ "$(cat "$TARGET_FILE" 2>/dev/null)" != "uninitialized" ]; then
    cat "$TARGET_FILE"
    exit 0
fi
mkdir -p "$TARGET_DIR"
if [ ! -s "$TARGET_FILE" ] || [ "$(cat "$TARGET_FILE" 2>/dev/null)" = "uninitialized" ]; then
    ID=""
    if command -v dbus-uuidgen >/dev/null 2>&1; then
        ID=$(dbus-uuidgen 2>/dev/null)
    fi
    if [ -z "$ID" ] && [ -r /dev/urandom ]; then
        ID=$(od -vN 16 -An -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
    fi
    if [ -z "$ID" ]; then
        ID=$(date +%s%N$$ 2>/dev/null | md5sum | cut -d' ' -f1)
    fi
    printf "%s\n" "$ID" > "$TARGET_FILE"
    chmod 444 "$TARGET_FILE" 2>/dev/null || true
fi
mkdir -p "${ROOT}/var/lib/dbus"
if [ ! -e "${ROOT}/var/lib/dbus/machine-id" ]; then
    ln -sf /etc/machine-id "${ROOT}/var/lib/dbus/machine-id" 2>/dev/null || true
fi
if [ "$PRINT_ONLY" -eq 1 ]; then
    cat "$TARGET_FILE"
fi
exit 0
MACHINEID_SETUP
    chmod +x /usr/bin/systemd-machine-id-setup

    # Unpackfs module — CRITICAL: tells Calamares where to find the live filesystem
    # Use dynamic detection script to find correct squashfs path
    cat > /usr/lib/taaos/fix-unpackfs.sh << 'UNPACKFS_SCRIPT'
#!/bin/bash
# Dynamically find the squashfs and write unpackfs.conf
SQUASHFS=""
for path in \
    /run/live/medium/live/filesystem.squashfs \
    /run/live/rootfs/filesystem.squashfs \
    /usr/lib/live/mount/rootfs/filesystem.squashfs \
    /lib/live/mount/medium/live/filesystem.squashfs \
    /cdrom/live/filesystem.squashfs; do
    if [ -f "$path" ]; then
        SQUASHFS="$path"
        break
    fi
done

# Fallback: search for any squashfs
if [ -z "$SQUASHFS" ]; then
    SQUASHFS=$(find /run /lib /usr/lib /cdrom 2>/dev/null -name 'filesystem.squashfs' -type f | head -1)
fi

if [ -n "$SQUASHFS" ]; then
    echo "[TaaOS] Found squashfs at: $SQUASHFS"
    cat > /etc/calamares/modules/unpackfs.conf << DYNCONF
---
unpack:
    -   source: "$SQUASHFS"
        sourcefs: "squashfs"
        destination: ""
DYNCONF
else
    echo "[TaaOS] ERROR: No squashfs found!"
    # Write a sensible default
    cat > /etc/calamares/modules/unpackfs.conf << DYNCONF
---
unpack:
    -   source: "/run/live/medium/live/filesystem.squashfs"
        sourcefs: "squashfs"
        destination: ""
DYNCONF
fi
UNPACKFS_SCRIPT
    chmod +x /usr/lib/taaos/fix-unpackfs.sh

    # Write a static default (will be overridden at launch time)
    cat > /etc/calamares/modules/unpackfs.conf << 'UNPACKFS_CONF'
---
unpack:
    -   source: "/run/live/medium/live/filesystem.squashfs"
        sourcefs: "squashfs"
        destination: ""
UNPACKFS_CONF

    # Post-installation Cleanup Module (shellprocess)
    cat > /etc/calamares/modules/shellprocess.conf << 'SHELLPROCESS_CONF'
---
# TaaOS Post-Install Cleanup Module
dontChroot: false
timeout: 600
script:
    - "/usr/lib/taaos/post-install.sh"
    - "-rm -f /home/*/Desktop/install-taaos.desktop"
    - "-rm -f /home/*/Desktop/taaos-installer.desktop"
    - "-rm -f /etc/skel/Desktop/install-taaos.desktop"
    - "-rm -f /etc/skel/Desktop/taaos-installer.desktop"
    - "-rm -f /usr/share/applications/taaos-installer.desktop"
    - "-rm -f /usr/share/applications/install-taaos.desktop"
    - "-rm -rf /usr/share/calamares/"
    - "-apt-get remove --purge -y calamares calamares-settings-debian live-boot live-config live-config-sysvinit"
    - "-apt-get autoremove -y"
SHELLPROCESS_CONF

    echo "[INSTALLER] Modules configured"
}

# -----------------------------------------------------------------------------
# SECTION 4: BRANDING
# -----------------------------------------------------------------------------
configure_branding() {
    echo "[INSTALLER] Configuring TaaOS branding..."
    
    BRAND_DIR="/etc/calamares/branding/taaos"
    mkdir -p "${BRAND_DIR}"
    
    # Branding descriptor
    cat > "${BRAND_DIR}/branding.desc" << 'BRANDING_DESC'
---
componentName: taaos

strings:
    productName:         TaaOS
    shortProductName:    TaaOS
    version:             2.0.0
    shortVersion:        2.0
    versionedName:       TaaOS 2.0.0
    shortVersionedName:  TaaOS 2.0
    bootloaderEntryName: TaaOS
    productUrl:          https://github.com/taasezer/TaaOS
    supportUrl:          https://github.com/taasezer/TaaOS/issues
    knownIssuesUrl:      https://github.com/taasezer/TaaOS/issues
    releaseNotesUrl:     https://github.com/taasezer/TaaOS/releases

images:
    productLogo:         "logo.png"
    productIcon:         "logo.png"

slideshow:               "show.qml"
slideshowAPI:            2

style:
    sidebarBackground:        "#0D1117"
    sidebarText:              "#FFFFFF"
    sidebarTextSelect:        "#FFFFFF"
    sidebarTextHighlight:     "#D40000"
    SidebarBackground:        "#0D1117"
    SidebarText:              "#FFFFFF"
    SidebarTextCurrent:       "#FFFFFF"
    SidebarBackgroundCurrent: "#D40000"
BRANDING_DESC

    cat > "${BRAND_DIR}/stylesheet.qss" << 'QSS_DESC'
/* TaaOS Calamares 3.3+ Stylesheet — High-Contrast Readable Dark Theme */
#mainApp {
    background-color: #0D1117;
    color: #E5E9F0;
}
#sidebarApp, #sidebarMenuApp {
    background-color: #090C10;
    color: #FFFFFF;
}
#sidebarMenuApp QLabel {
    color: #FFFFFF;
}
QWidget {
    color: #E5E9F0;
    background-color: #0D1117;
}
QLabel {
    color: #E5E9F0;
    background-color: transparent;
}
QPushButton {
    background-color: #161B22;
    color: #FFFFFF;
    border: 1px solid #30363D;
    border-radius: 5px;
    padding: 6px 14px;
    font-weight: bold;
}
QPushButton:hover {
    background-color: #D40000;
    border-color: #FF2A2A;
    color: #FFFFFF;
}
QPushButton:disabled {
    background-color: #0D1117;
    color: #6E7681;
    border-color: #21262D;
}
QComboBox, QLineEdit, QTreeView, QListView {
    background-color: #161B22;
    color: #FFFFFF;
    border: 1px solid #30363D;
    border-radius: 4px;
    padding: 4px;
    selection-background-color: #D40000;
    selection-color: #FFFFFF;
}
QRadioButton, QCheckBox {
    color: #E5E9F0;
    spacing: 8px;
}
QSS_DESC

    cat > "${BRAND_DIR}/show.qml" << 'QML_DESC'
import QtQuick 2.0
import QtQuick.Controls 2.0

Item {
    id: presentation
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "#0D1117"

        Column {
            anchors.centerIn: parent
            spacing: 16

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TaaOS 2.0"
                font.pixelSize: 32
                font.bold: true
                color: "#D40000"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Developer Distribution — Deterministic, Fast, Modular"
                font.pixelSize: 14
                color: "#E5E9F0"
            }
        }
    }
}
QML_DESC

    # Use official TaaOS logo if available, otherwise generate Rosso Corsa T emblem
    if [ -f /usr/share/pixmaps/taaos-logo.png ]; then
        cp -f /usr/share/pixmaps/taaos-logo.png "${BRAND_DIR}/logo.png"
    elif command -v convert &> /dev/null; then
        convert -size 128x128 xc:'#0D1117' \
            -font DejaVu-Sans-Bold -pointsize 56 \
            -fill '#D40000' -gravity center \
            -annotate 0 "T" \
            "${BRAND_DIR}/logo.png" 2>/dev/null || true
    else
        echo "[INSTALLER] ImageMagick not available, placeholder images not created"
    fi

    # CRITICAL: Ensure ALL branding images exist (Calamares FATALS if any are missing)
    # Create minimal valid 1x1 PNG fallbacks for any missing images
    _create_fallback_png() {
        local target="$1"
        if [ ! -f "$target" ]; then
            echo "[INSTALLER] Creating fallback image: $target"
            # Minimal valid 1x1 blue PNG (67 bytes)
            printf '\x89PNG\r\n\x1a\n' > "$target"
            printf '\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02' >> "$target"
            printf '\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx' >> "$target"
            printf '\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N' >> "$target"
            printf '\x00\x00\x00\x00IEND\xaeB\x60\x82' >> "$target"
        fi
    }
    _create_fallback_png "${BRAND_DIR}/logo.png"
    _create_fallback_png "${BRAND_DIR}/welcome.png"
    
    echo "[INSTALLER] All branding images verified"
    
    echo "[INSTALLER] Branding configured"
}

# -----------------------------------------------------------------------------
# SECTION 5: DESKTOP INTEGRATION
# -----------------------------------------------------------------------------
create_desktop_entry() {
    echo "[INSTALLER] Creating desktop entry..."
    
    # Create Calamares launcher wrapper (auto-elevates to root, releases swap locks on target disks, fixes unpackfs)
    mkdir -p /usr/lib/taaos /usr/local/bin
    cat > /usr/local/bin/taaos-install << 'WRAPPER_SCRIPT'
#!/bin/bash
# TaaOS Installer Launcher & Auto-Root Wrapper
xhost +local:root 2>/dev/null || true

if [ "$EUID" -ne 0 ]; then
    exec sudo -E /usr/local/bin/taaos-install "$@"
fi

echo "[TaaOS] Preparing installer..."

# Release any active swap or leftover mounts on target disks so Calamares kpmcore can read full disk capacity
swapoff -a 2>/dev/null || true
umount -R /tmp/calamares-* 2>/dev/null || true

# Absolute failsafe for UnpackFS
SQ_PATH=$(find /run /lib /media -type f -name "filesystem.squashfs" 2>/dev/null | head -n 1)
if [ -z "$SQ_PATH" ]; then
    SQ_PATH=$(find /run /lib /media -type f -name "*.squashfs" 2>/dev/null | grep -v hotfix | head -n 1)
fi

HOTFIX_PATH=""
if [ -n "$SQ_PATH" ]; then
    SQ_DIR=$(dirname "$SQ_PATH")
    if [ -f "$SQ_DIR/z-taaos-hotfix.squashfs" ]; then
        HOTFIX_PATH="$SQ_DIR/z-taaos-hotfix.squashfs"
    fi
fi

mkdir -p /etc/calamares/modules
if [ -n "$SQ_PATH" ]; then
    echo "[TaaOS] Found live filesystem at: $SQ_PATH"
    if [ -n "$HOTFIX_PATH" ]; then
        cat > /etc/calamares/modules/unpackfs.conf << UNPACKEOF
---
unpack:
    -   source: "$SQ_PATH"
        sourcefs: "squashfs"
        destination: ""
    -   source: "$HOTFIX_PATH"
        sourcefs: "squashfs"
        destination: ""
        optional: true
UNPACKEOF
    else
        cat > /etc/calamares/modules/unpackfs.conf << UNPACKEOF
---
unpack:
    -   source: "$SQ_PATH"
        sourcefs: "squashfs"
        destination: ""
UNPACKEOF
    fi
fi

# Ensure systemd-free machine-id configuration
cat > /etc/calamares/modules/machineid.conf << 'MACHINECONF'
---
systemd: "systemd-style"
dbus: true
symlink: true
dbus-symlink: true
entropy-copy: false
MACHINECONF

exec /usr/bin/calamares "$@"
WRAPPER_SCRIPT
    chmod +x /usr/local/bin/taaos-install
    ln -sf /usr/local/bin/taaos-install /usr/local/bin/calamares

    # Desktop entry for installer — runs the wrapper which escalates to root securely via sudo
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/taaos-installer.desktop << 'INSTALLER_DESKTOP'
[Desktop Entry]
Type=Application
Version=1.0
Name=Sistemi Kur
Comment=TaaOS İşletim Sistemini Kur
Comment[tr]=TaaOS'u sisteminize kurun
Icon=calamares
Exec=/usr/local/bin/taaos-install
Categories=System;
Terminal=false
StartupNotify=true
StartupWMClass=calamares
INSTALLER_DESKTOP

    # Copy to desktop for live session
    mkdir -p /etc/skel/Desktop
    cp /usr/share/applications/taaos-installer.desktop /etc/skel/Desktop/
    chmod +x /etc/skel/Desktop/taaos-installer.desktop
    
    # SIKINTI ÇÖZÜCÜ: Debian'ın ve Eski TaaOS'un Çiftleyen Kısayollarını Kesin Olarak Yok Et
    rm -f /etc/skel/Desktop/install-debian.desktop 2>/dev/null || true
    rm -f /usr/share/applications/install-debian.desktop 2>/dev/null || true
    rm -f /etc/skel/Desktop/debian-installer-launcher.desktop 2>/dev/null || true
    rm -f /usr/share/applications/debian-installer-launcher.desktop 2>/dev/null || true
    rm -f /etc/skel/Desktop/install-taaos.desktop 2>/dev/null || true
    rm -f /usr/share/applications/install-taaos.desktop 2>/dev/null || true
    rm -f /etc/skel/Desktop/calamares.desktop 2>/dev/null || true
    rm -f /usr/share/applications/calamares.desktop 2>/dev/null || true
    
    echo "[INSTALLER] Desktop entry created and duplicates purged"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "[INSTALLER] Starting Calamares Setup..."
    echo ""

    install_calamares
    echo ""
    
    configure_calamares
    echo ""
    
    configure_modules
    echo ""
    
    configure_branding
    echo ""
    
    create_desktop_entry
    echo ""

    echo "=============================================="
    echo "  Calamares Installer Setup - COMPLETE!"
    echo "=============================================="
    echo ""
    echo "  Installer will be available on the desktop"
    echo "  in live mode as 'Install TaaOS'"
    echo ""
}

# Run main function
main "$@"
