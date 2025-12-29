#!/bin/bash
# =============================================================================
# TaaOS Performance Optimization Script
# =============================================================================
# Script: optimize-system.sh
# Purpose: Configure zRAM, TLP, Preload, and Tuned for optimal performance
# =============================================================================

set -e

echo "=============================================="
echo "  TaaOS Performance Optimization"
echo "=============================================="

# -----------------------------------------------------------------------------
# SECTION 1: zRAM COMPRESSED SWAP
# -----------------------------------------------------------------------------
setup_zram() {
    echo "[PERF] Installing and configuring zRAM..."
    
    apt-get update
    apt-get install -y zram-tools
    
    # Configure zRAM settings
    cat > /etc/default/zramswap << 'ZRAM_CONFIG'
# TaaOS zRAM Configuration
# =============================================================================
# zRAM creates compressed RAM-based swap, improving performance on low-RAM systems
# =============================================================================

# Percentage of RAM to use for zRAM (50% is optimal for most systems)
PERCENT=50

# Compression algorithm (lz4 is fastest, zstd has best ratio)
ALGO=lz4

# Priority (higher than disk swap)
PRIORITY=100

# Number of zRAM devices (auto = one per CPU core)
# CORES=auto
ZRAM_CONFIG

    # Enable zRAM service
    systemctl enable zramswap || true
    
    echo "[PERF] zRAM configured: 50% of RAM as compressed swap"
}

# -----------------------------------------------------------------------------
# SECTION 2: TLP BATTERY MANAGEMENT
# -----------------------------------------------------------------------------
setup_tlp() {
    echo "[PERF] Installing TLP for power management..."
    
    apt-get install -y tlp tlp-rdw
    
    # Create TaaOS-optimized TLP configuration
    cat > /etc/tlp.d/01-taaos.conf << 'TLP_CONFIG'
# =============================================================================
# TaaOS TLP Configuration - Power Management
# =============================================================================

# Operation mode on AC power
TLP_DEFAULT_MODE=AC
TLP_PERSISTENT_DEFAULT=0

# CPU Frequency Scaling
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU Performance Boost
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# CPU Energy/Performance Policies
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# Platform Power Profiles (for newer kernels)
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# SATA Link Power Management
SATA_LINKPWR_ON_AC="med_power_with_dipm max_performance"
SATA_LINKPWR_ON_BAT="med_power_with_dipm min_power"

# PCIe Power Management
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave

# Runtime Power Management
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

# USB Autosuspend
USB_AUTOSUSPEND=1
USB_EXCLUDE_BTUSB=1
USB_EXCLUDE_PHONE=1

# WiFi Power Save
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Audio Power Save
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1

# Disk APM Level
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

# NVMe Runtime PM
NVME_RUNTIME_PM_ON_AC=off
NVME_RUNTIME_PM_ON_BAT=auto

# Battery Care (ThinkPads, some ASUS, Huawei)
# Uncomment and adjust for your laptop
# START_CHARGE_THRESH_BAT0=75
# STOP_CHARGE_THRESH_BAT0=80
TLP_CONFIG

    # Enable and start TLP
    systemctl enable tlp || true
    systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null || true
    
    echo "[PERF] TLP configured for optimal power management"
}

# -----------------------------------------------------------------------------
# SECTION 3: PRELOAD APPLICATION PREFETCHER
# -----------------------------------------------------------------------------
setup_preload() {
    echo "[PERF] Installing Preload daemon..."
    
    apt-get install -y preload
    
    # Configure preload
    cat > /etc/preload.conf << 'PRELOAD_CONFIG'
# =============================================================================
# TaaOS Preload Configuration
# =============================================================================
# Preload monitors application usage and preloads frequently used apps

[model]
# The model controls how preload predicts future application launches

# Cycle time (seconds) - how often preload checks running apps
cycle = 20

# Minimum time (seconds) an app must run to be considered
minsize = 2000000

# Memory portion to use for preloading (0-100)
memtotal = 50
memfree = 50
memcached = 0

[system]
# Sortstrategy: 0 = sort by correlation, 1 = sort by time
sortstrategy = 3

# Autosave interval (seconds)
autosave = 3600

# Map file prefix
mapprefix = /usr/lib
exeprefix = /usr/

[log]
# Logging level: 0 = none, 1 = error, 2 = warning, 3 = info, 4 = debug
loglevel = 2

# Nice level (ionice)
ionice = 7
PRELOAD_CONFIG

    # Enable preload service
    systemctl enable preload || true
    
    echo "[PERF] Preload daemon configured"
}

# -----------------------------------------------------------------------------
# SECTION 4: TUNED PERFORMANCE PROFILES
# -----------------------------------------------------------------------------
setup_tuned() {
    echo "[PERF] Installing Tuned performance profiles..."
    
    apt-get install -y tuned tuned-utils
    
    # Create TaaOS balanced profile directory
    PROFILE_DIR="/etc/tuned/taaos-balanced"
    mkdir -p "${PROFILE_DIR}"
    
    # Create the TaaOS balanced profile
    cat > "${PROFILE_DIR}/tuned.conf" << 'TUNED_PROFILE'
# =============================================================================
# TaaOS Balanced Performance Profile
# =============================================================================
# Custom Tuned profile optimized for engineering workloads
# Balances performance with power efficiency
# =============================================================================

[main]
summary=TaaOS Balanced - Optimized for Engineering Workloads
include=balanced

[cpu]
# Governor: performance on AC, ondemand otherwise
governor=ondemand
energy_perf_bias=normal
min_perf_pct=10

[vm]
# Virtual memory tuning
transparent_hugepages=madvise

[sysctl]
# Kernel parameters for better performance

# VM Swappiness (lower = prefer RAM over swap)
vm.swappiness=10

# VFS Cache Pressure (how aggressively kernel reclaims memory from caches)
vm.vfs_cache_pressure=50

# Dirty Ratio (percentage of RAM that can be dirty before write-back)
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# Maximum number of memory map areas
vm.max_map_count=262144

# Network optimizations
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_fastopen=3

# File system optimizations
fs.inotify.max_user_watches=524288
fs.file-max=2097152

# Kernel scheduling
kernel.sched_autogroup_enabled=1

[disk]
# Disk tuning
readahead=4096
elevator=mq-deadline

[audio]
# Audio latency optimization
timeout=0

[script]
# Custom script for additional tuning
script=${i:PROFILE_DIR}/script.sh
TUNED_PROFILE

    # Create the profile script
    cat > "${PROFILE_DIR}/script.sh" << 'TUNED_SCRIPT'
#!/bin/bash
# TaaOS Tuned Profile Script

case "$1" in
    start)
        # Enable all CPU cores
        for cpu in /sys/devices/system/cpu/cpu*/online; do
            echo 1 > "$cpu" 2>/dev/null || true
        done
        
        # Disable CPU vulnerability mitigations for maximum performance (optional)
        # Uncomment if you prioritize performance over security
        # echo off > /sys/devices/system/cpu/vulnerabilities/mds/state 2>/dev/null || true
        ;;
    stop)
        # Cleanup on profile deactivation
        ;;
esac
exit 0
TUNED_SCRIPT

    chmod +x "${PROFILE_DIR}/script.sh"
    
    # Create a performance-focused variant
    PERF_DIR="/etc/tuned/taaos-performance"
    mkdir -p "${PERF_DIR}"
    
    cat > "${PERF_DIR}/tuned.conf" << 'TUNED_PERF'
[main]
summary=TaaOS Performance - Maximum Performance Mode
include=throughput-performance

[cpu]
governor=performance
energy_perf_bias=performance
force_latency=1

[sysctl]
vm.swappiness=1
vm.dirty_ratio=40
vm.dirty_background_ratio=10
kernel.sched_min_granularity_ns=10000000
kernel.sched_wakeup_granularity_ns=15000000

[bootloader]
cmdline=processor.max_cstate=1 intel_idle.max_cstate=0
TUNED_PERF

    # Enable tuned service and set TaaOS balanced as default
    systemctl enable tuned || true
    
    # Set the active profile
    tuned-adm profile taaos-balanced 2>/dev/null || echo "[PERF] Profile will be activated on boot"
    
    echo "[PERF] Tuned profiles created: taaos-balanced, taaos-performance"
}

# -----------------------------------------------------------------------------
# SECTION 5: ADDITIONAL SYSTEM OPTIMIZATIONS
# -----------------------------------------------------------------------------
additional_optimizations() {
    echo "[PERF] Applying additional system optimizations..."
    
    # Create sysctl configuration for TaaOS
    cat > /etc/sysctl.d/99-taaos-performance.conf << 'SYSCTL_CONFIG'
# =============================================================================
# TaaOS System Performance Tuning
# =============================================================================

# Virtual Memory
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.overcommit_ratio = 50

# Network Performance
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.optmem_max = 65536
net.ipv4.tcp_rmem = 4096 1048576 2097152
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1

# File System
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512

# Kernel
kernel.pid_max = 4194304
kernel.threads-max = 4194304
SYSCTL_CONFIG

    echo "[PERF] Additional optimizations applied"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "[PERF] Starting TaaOS Performance Optimization..."
    echo ""

    setup_zram
    echo ""
    
    setup_tlp
    echo ""
    
    setup_preload
    echo ""
    
    setup_tuned
    echo ""
    
    additional_optimizations
    echo ""

    echo "=============================================="
    echo "  TaaOS Performance Optimization - COMPLETE!"
    echo "=============================================="
    echo ""
    echo "  Configured Services:"
    echo "  - zRAM: 50% compressed swap"
    echo "  - TLP: Battery/power management"
    echo "  - Preload: Application prefetching"
    echo "  - Tuned: taaos-balanced profile active"
    echo ""
}

# Run main function
main "$@"
