#!/bin/bash
# =============================================================================
# TaaOS Calamares Installer Configuration
# =============================================================================
# Script: setup-calamares.sh
# Purpose: Install and configure Calamares graphical installer
# =============================================================================

set -e

echo "=============================================="
echo "  TaaOS Calamares Installer Setup"
echo "=============================================="

# -----------------------------------------------------------------------------
# SECTION 1: CALAMARES INSTALLATION
# -----------------------------------------------------------------------------
install_calamares() {
    echo "[INSTALLER] Installing Calamares..."
    
    apt-get update
    
    # Install Calamares and dependencies
    apt-get install -y \
        calamares \
        calamares-settings-debian \
        qml-module-qtquick2 \
        qml-module-qtquick-controls \
        qml-module-qtquick-controls2 \
        qml-module-qtquick-layouts \
        qml-module-qtquick-window2
    
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
    - services-systemd
    - grubcfg
    - bootloader
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
    requiredStorage: 20
    requiredRam: 2.0
    internetCheckUrl: https://example.com
    check:
        - storage
        - ram
        - power
        - internet
        - root
    required:
        - storage
        - ram
        - root

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
restartNowCommand: "systemctl reboot"
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
DISPLAYMANAGER_CONF

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
    version:             1.0
    shortVersion:        1.0
    versionedName:       TaaOS 1.0
    shortVersionedName:  TaaOS 1.0
    bootloaderEntryName: TaaOS
    productUrl:          https://github.com/taaos
    supportUrl:          https://github.com/taaos/issues
    knownIssuesUrl:      https://github.com/taaos/issues
    releaseNotesUrl:     https://github.com/taaos/releases

images:
    productLogo:         "logo.png"
    productIcon:         "logo.png"
    productWelcome:      "welcome.png"

slideshow:               "show.qml"

style:
    sidebarBackground:   "#1a1a2e"
    sidebarText:         "#FFFFFF"
    sidebarTextSelect:   "#00d4ff"
    sidebarTextHighlight: "#00d4ff"
BRANDING_DESC

    # Create slideshow QML
    cat > "${BRAND_DIR}/show.qml" << 'SLIDESHOW_QML'
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"
            
            Text {
                anchors.centerIn: parent
                text: "Welcome to TaaOS"
                color: "#00d4ff"
                font.pixelSize: 48
                font.bold: true
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: 60
                text: "Engineering Excellence in Every Byte"
                color: "#ffffff"
                font.pixelSize: 24
            }
        }
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                Text {
                    text: "⚙️ Custom Kernel"
                    color: "#00d4ff"
                    font.pixelSize: 32
                    font.bold: true
                }
                
                Text {
                    text: "Built with ECC memory support,\nPREEMPT scheduling, and SELinux"
                    color: "#ffffff"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                Text {
                    text: "🤖 AI-Powered"
                    color: "#00d4ff"
                    font.pixelSize: 32
                    font.bold: true
                }
                
                Text {
                    text: "Natural Engine - translate plain English\nto Linux commands using AI"
                    color: "#ffffff"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                Text {
                    text: "🛡️ Security First"
                    color: "#00d4ff"
                    font.pixelSize: 32
                    font.bold: true
                }
                
                Text {
                    text: "Fail2ban, ClamAV, automatic security updates,\nand comprehensive system hardening"
                    color: "#ffffff"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                Text {
                    text: "🚀 DevOps Ready"
                    color: "#00d4ff"
                    font.pixelSize: 32
                    font.bold: true
                }
                
                Text {
                    text: "Docker, Portainer, Cockpit, Virt-Manager\nAll pre-configured and ready to use"
                    color: "#ffffff"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
SLIDESHOW_QML

    # Create placeholder images
    if command -v convert &> /dev/null; then
        # Logo
        convert -size 128x128 xc:'#1a1a2e' \
            -font DejaVu-Sans-Bold -pointsize 48 \
            -fill '#00d4ff' -gravity center \
            -annotate 0 "T" \
            "${BRAND_DIR}/logo.png" 2>/dev/null || true
        
        # Welcome image
        convert -size 800x300 \
            -define gradient:direction=east \
            gradient:'#0a0a14-#1a1a2e' \
            -font DejaVu-Sans-Bold -pointsize 64 \
            -fill '#00d4ff' -gravity center \
            -annotate 0 "TaaOS" \
            "${BRAND_DIR}/welcome.png" 2>/dev/null || true
    else
        echo "[INSTALLER] ImageMagick not available, placeholder images not created"
    fi
    
    echo "[INSTALLER] Branding configured"
}

# -----------------------------------------------------------------------------
# SECTION 5: DESKTOP INTEGRATION
# -----------------------------------------------------------------------------
create_desktop_entry() {
    echo "[INSTALLER] Creating desktop entry..."
    
    # Desktop entry for installer
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/taaos-installer.desktop << 'INSTALLER_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Install TaaOS
Comment=Install TaaOS to your system
Icon=calamares
Exec=pkexec calamares
Categories=System;
Terminal=false
StartupNotify=true
X-AppStream-Ignore=true
INSTALLER_DESKTOP

    # Copy to desktop for live session
    mkdir -p /etc/skel/Desktop
    cp /usr/share/applications/taaos-installer.desktop /etc/skel/Desktop/
    chmod +x /etc/skel/Desktop/taaos-installer.desktop
    
    echo "[INSTALLER] Desktop entry created"
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
