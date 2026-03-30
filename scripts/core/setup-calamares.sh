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
    - services-systemd
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
    requiredStorage: 8
    requiredRam: 1.0
    internetCheckUrl: https://example.com
    check:
        - storage
        - ram
    required:
        - storage

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
    - "-apt-get remove --purge -y calamares calamares-settings-debian live-boot live-config live-config-systemd"
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
    version:             1.0.0
    shortVersion:        1.0.0
    versionedName:       TaaOS 1.0.0
    shortVersionedName:  TaaOS 1.0.0
    bootloaderEntryName: TaaOS
    productUrl:          https://github.com/taasezer/TaaOS
    supportUrl:          https://github.com/taasezer/TaaOS/issues
    knownIssuesUrl:      https://github.com/taasezer/TaaOS/issues
    releaseNotesUrl:     https://github.com/taasezer/TaaOS/releases

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
    
    # Create Calamares launcher wrapper (fixes unpackfs + runs calamares)
    mkdir -p /usr/lib/taaos
    cat > /usr/local/bin/taaos-install << 'WRAPPER_SCRIPT'
#!/bin/bash
# TaaOS Installer Launcher
# Absolute Kali-style fix for X11 Live USB installer authentication:
xhost +local:root
echo "[TaaOS] Preparing installer..."
if [ -f /usr/lib/taaos/fix-unpackfs.sh ]; then
    bash /usr/lib/taaos/fix-unpackfs.sh 2>/dev/null || true
fi
exec sudo -E calamares "$@"
WRAPPER_SCRIPT
    chmod +x /usr/local/bin/taaos-install

    # Desktop entry for installer — runs the wrapper which escalates to root securely via sudo
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/taaos-installer.desktop << 'INSTALLER_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Install TaaOS
Name[tr]=TaaOS Kur
Comment=Install TaaOS to your system
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
