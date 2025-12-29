#!/bin/bash
# =============================================================================
# TaaOS System Administration Tools
# =============================================================================
# Script: install-admin-tools.sh
# Purpose: Install Cockpit, Timeshift, and Virt-Manager for system management
# =============================================================================

set -e

echo "=============================================="
echo "  TaaOS System Administration Tools"
echo "=============================================="

# -----------------------------------------------------------------------------
# SECTION 1: COCKPIT WEB MANAGEMENT
# -----------------------------------------------------------------------------
install_cockpit() {
    echo "[ADMIN] Installing Cockpit..."
    
    apt-get update
    
    # Install Cockpit and extensions
    apt-get install -y \
        cockpit \
        cockpit-storaged \
        cockpit-networkmanager \
        cockpit-packagekit \
        cockpit-pcp \
        cockpit-sosreport
    
    # Install Cockpit Podman/Docker integration if Docker is installed
    if command -v docker &> /dev/null; then
        apt-get install -y cockpit-docker 2>/dev/null || true
    fi
    
    # Install Cockpit Machines for VM management if libvirt is available
    apt-get install -y cockpit-machines 2>/dev/null || true
    
    # Enable Cockpit socket
    echo "[ADMIN] Enabling Cockpit..."
    systemctl enable cockpit.socket || true
    
    # Configure Cockpit
    mkdir -p /etc/cockpit
    cat > /etc/cockpit/cockpit.conf << 'COCKPIT_CONF'
[WebService]
# Login settings
LoginTitle = TaaOS System Management
AllowUnencrypted = false

# Session settings
IdleTimeout = 15
MaxStartups = 10

[Log]
Fatal = criticals warnings

[Session]
Banner = /etc/cockpit/issue.cockpit
COCKPIT_CONF

    # Create login banner
    cat > /etc/cockpit/issue.cockpit << 'COCKPIT_BANNER'

    ████████╗ █████╗  █████╗  ██████╗ ███████╗
    ╚══██╔══╝██╔══██╗██╔══██╗██╔═══██╗██╔════╝
       ██║   ███████║███████║██║   ██║███████╗
       ██║   ██╔══██║██╔══██║██║   ██║╚════██║
       ██║   ██║  ██║██║  ██║╚██████╔╝███████║
       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

    System Management Console

COCKPIT_BANNER

    # Configure UFW if installed
    if command -v ufw &> /dev/null; then
        echo "[ADMIN] Allowing Cockpit through UFW..."
        ufw allow 9090/tcp comment 'Cockpit Web Console' 2>/dev/null || true
    fi
    
    # Create desktop entry
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/cockpit.desktop << 'COCKPIT_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Cockpit
Comment=System Administration Web Console
Icon=utilities-system-monitor
Exec=xdg-open https://localhost:9090
Categories=System;Settings;
Terminal=false
COCKPIT_DESKTOP

    echo "[ADMIN] Cockpit installed on port 9090"
}

# -----------------------------------------------------------------------------
# SECTION 2: TIMESHIFT SYSTEM SNAPSHOTS
# -----------------------------------------------------------------------------
install_timeshift() {
    echo "[ADMIN] Installing Timeshift..."
    
    # Timeshift is available in Debian repositories
    apt-get install -y timeshift
    
    # Create default configuration
    mkdir -p /etc/timeshift
    cat > /etc/timeshift/timeshift.json << 'TIMESHIFT_CONF'
{
  "backup_device_uuid" : "",
  "parent_device_uuid" : "",
  "do_first_run" : "true",
  "btrfs_mode" : "false",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
    "/home/**/.cache/**",
    "/home/**/.local/share/Trash/**",
    "/home/**/Downloads/**",
    "/var/cache/**",
    "/var/tmp/**"
  ],
  "exclude-apps" : []
}
TIMESHIFT_CONF

    # Create CLI wrapper for easy access
    cat > /usr/local/bin/snapshot << 'SNAPSHOT_SCRIPT'
#!/bin/bash
# TaaOS Snapshot Helper

case "${1:-help}" in
    create)
        echo "Creating system snapshot..."
        sudo timeshift --create --comments "${2:-Manual snapshot}"
        ;;
    list)
        sudo timeshift --list
        ;;
    restore)
        echo "Starting restore wizard..."
        sudo timeshift --restore
        ;;
    delete)
        if [ -n "$2" ]; then
            sudo timeshift --delete --snapshot "$2"
        else
            echo "Usage: snapshot delete <snapshot-name>"
        fi
        ;;
    gui)
        sudo timeshift-gtk &
        ;;
    help|*)
        echo "TaaOS Snapshot Manager"
        echo ""
        echo "Usage: snapshot <command> [args]"
        echo ""
        echo "Commands:"
        echo "  create [comment]  Create new snapshot"
        echo "  list              List all snapshots"
        echo "  restore           Restore from snapshot"
        echo "  delete <name>     Delete a snapshot"
        echo "  gui               Open graphical interface"
        ;;
esac
SNAPSHOT_SCRIPT

    chmod +x /usr/local/bin/snapshot
    
    echo "[ADMIN] Timeshift installed with daily/weekly snapshots"
}

# -----------------------------------------------------------------------------
# SECTION 3: VIRT-MANAGER & KVM
# -----------------------------------------------------------------------------
install_virtmanager() {
    echo "[ADMIN] Installing Virt-Manager and KVM..."
    
    # Check for virtualization support
    if grep -E '(vmx|svm)' /proc/cpuinfo &> /dev/null; then
        echo "[ADMIN] CPU virtualization support detected"
    else
        echo "[ADMIN] WARNING: CPU may not support virtualization"
    fi
    
    # Install KVM and QEMU
    apt-get install -y \
        qemu-kvm \
        qemu-system-x86 \
        qemu-utils \
        libvirt-daemon-system \
        libvirt-clients \
        bridge-utils \
        virtinst \
        virt-manager \
        virt-viewer \
        ovmf
    
    # Install additional libvirt packages
    apt-get install -y \
        libvirt-daemon-driver-qemu \
        libvirt-daemon-driver-storage-core \
        libvirt-daemon-driver-network 2>/dev/null || true
    
    # Enable libvirt service
    echo "[ADMIN] Enabling libvirt..."
    systemctl enable libvirtd || true
    systemctl enable virtlogd || true
    
    # Add engineer user to required groups
    echo "[ADMIN] Adding user to virtualization groups..."
    usermod -aG libvirt engineer 2>/dev/null || true
    usermod -aG kvm engineer 2>/dev/null || true
    usermod -aG libvirt-qemu engineer 2>/dev/null || true
    
    # Configure default network
    echo "[ADMIN] Configuring default virtual network..."
    cat > /etc/libvirt/qemu/networks/default.xml.taaos << 'LIBVIRT_NET'
<network>
  <name>default</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
LIBVIRT_NET

    # Create VM storage pool directory
    mkdir -p /var/lib/libvirt/images
    chmod 755 /var/lib/libvirt/images
    
    # Configure KVM tuning
    cat > /etc/modprobe.d/kvm.conf << 'KVM_CONF'
# TaaOS KVM Performance Tuning
options kvm_intel nested=1
options kvm_intel enable_apicv=1
options kvm_amd nested=1
KVM_CONF

    # Create quick VM creation script
    cat > /usr/local/bin/taaos-vm << 'VM_SCRIPT'
#!/bin/bash
# TaaOS Quick VM Creator

show_help() {
    echo "TaaOS VM Manager"
    echo ""
    echo "Usage: taaos-vm <command> [options]"
    echo ""
    echo "Commands:"
    echo "  list                  List all VMs"
    echo "  start <name>          Start a VM"
    echo "  stop <name>           Stop a VM gracefully"
    echo "  force-stop <name>     Force stop a VM"
    echo "  console <name>        Open VM console"
    echo "  create <name> <iso>   Create new VM from ISO"
    echo "  delete <name>         Delete a VM"
    echo "  gui                   Open Virt-Manager"
}

case "${1:-help}" in
    list)
        virsh list --all
        ;;
    start)
        virsh start "$2"
        ;;
    stop)
        virsh shutdown "$2"
        ;;
    force-stop)
        virsh destroy "$2"
        ;;
    console)
        virt-viewer "$2" &
        ;;
    gui)
        virt-manager &
        ;;
    create)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: taaos-vm create <name> <iso-path>"
            exit 1
        fi
        virt-install \
            --name "$2" \
            --ram 4096 \
            --vcpus 2 \
            --disk path=/var/lib/libvirt/images/$2.qcow2,size=40 \
            --os-variant debian11 \
            --network network=default \
            --graphics spice \
            --cdrom "$3" \
            --boot uefi
        ;;
    delete)
        virsh destroy "$2" 2>/dev/null || true
        virsh undefine "$2" --remove-all-storage
        ;;
    help|*)
        show_help
        ;;
esac
VM_SCRIPT

    chmod +x /usr/local/bin/taaos-vm
    
    # Add aliases
    cat >> /etc/bash.bashrc << 'VM_ALIASES'

# VM management aliases
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
VM_ALIASES

    echo "[ADMIN] Virt-Manager and KVM installed"
}

# -----------------------------------------------------------------------------
# SECTION 4: ADDITIONAL ADMIN UTILITIES
# -----------------------------------------------------------------------------
install_admin_utilities() {
    echo "[ADMIN] Installing additional admin utilities..."
    
    # System monitoring tools
    apt-get install -y \
        htop \
        iotop \
        iftop \
        nethogs \
        ncdu \
        glances \
        dstat 2>/dev/null || echo "[ADMIN] Some monitoring tools skipped"
    
    # Network utilities
    apt-get install -y \
        nmap \
        tcpdump \
        wireshark-common \
        net-tools \
        traceroute \
        mtr-tiny 2>/dev/null || echo "[ADMIN] Some network tools skipped"
    
    # Disk utilities
    apt-get install -y \
        gparted \
        smartmontools \
        hdparm 2>/dev/null || echo "[ADMIN] Some disk tools skipped"
    
    echo "[ADMIN] Admin utilities installed"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "[ADMIN] Starting System Administration Tools Setup..."
    echo ""

    install_cockpit
    echo ""
    
    install_timeshift
    echo ""
    
    install_virtmanager
    echo ""
    
    install_admin_utilities
    echo ""

    echo "=============================================="
    echo "  System Administration Tools - COMPLETE!"
    echo "=============================================="
    echo ""
    echo "  Installed Components:"
    echo "  - Cockpit (https://localhost:9090)"
    echo "  - Timeshift (snapshot command)"
    echo "  - Virt-Manager & KVM (taaos-vm command)"
    echo "  - System monitoring tools"
    echo ""
    echo "  Commands:"
    echo "  - snapshot create|list|restore|gui"
    echo "  - taaos-vm list|start|stop|create|gui"
    echo "  - glances (system monitor)"
    echo ""
}

# Run main function
main "$@"
