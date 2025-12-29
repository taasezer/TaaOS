#!/bin/bash
# =============================================================================
# TaaOS Security Hardening Script
# =============================================================================
# Script: harden-system.sh
# Purpose: Configure Fail2ban, ClamAV, Lynis, and Automatic Updates
# =============================================================================

set -e

echo "=============================================="
echo "  TaaOS Security Hardening"
echo "=============================================="

# -----------------------------------------------------------------------------
# SECTION 1: FAIL2BAN INTRUSION PREVENTION
# -----------------------------------------------------------------------------
setup_fail2ban() {
    echo "[SECURITY] Installing Fail2ban..."
    
    apt-get update
    apt-get install -y fail2ban
    
    # Create jail.local configuration
    cat > /etc/fail2ban/jail.local << 'FAIL2BAN_CONFIG'
# =============================================================================
# TaaOS Fail2ban Configuration
# =============================================================================
# Intrusion prevention system - blocks brute-force attacks
# =============================================================================

[DEFAULT]
# Ban duration (10 minutes default, increase for repeat offenders)
bantime = 10m

# Time window for counting failures
findtime = 10m

# Max failures before ban
maxretry = 5

# Action to take (ban IP using iptables/nftables)
banaction = iptables-multiport
banaction_allports = iptables-allports

# Ignore local networks
ignoreip = 127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

# Email notifications (configure if needed)
# destemail = admin@localhost
# sender = fail2ban@localhost
# mta = sendmail

# Backend (auto-detect)
backend = auto

# =============================================================================
# SSH Protection (ENABLED)
# =============================================================================
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
findtime = 10m

# Aggressive mode for repeated offenders
[sshd-aggressive]
enabled = true
port = ssh
filter = sshd[mode=aggressive]
logpath = /var/log/auth.log
maxretry = 2
bantime = 24h
findtime = 1h

# =============================================================================
# Additional Services Protection
# =============================================================================

# Apache/Nginx (if installed)
[apache-auth]
enabled = false
port = http,https
filter = apache-auth
logpath = /var/log/apache*/*error.log
maxretry = 5

[nginx-http-auth]
enabled = false
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5

# Postfix (if installed)
[postfix]
enabled = false
port = smtp,465,submission
filter = postfix
logpath = /var/log/mail.log
maxretry = 5

# PAM Generic
[pam-generic]
enabled = true
filter = pam-generic
logpath = /var/log/auth.log
maxretry = 5
bantime = 1h

# =============================================================================
# Custom TaaOS Rules
# =============================================================================
[taaos-web]
enabled = false
port = 80,443,8080,3000,5000
filter = taaos-web
logpath = /var/log/taaos/*.log
maxretry = 10
bantime = 30m

[recidive]
# Ban repeat offenders for longer periods
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
banaction = iptables-allports
bantime = 1w
findtime = 1d
maxretry = 5
FAIL2BAN_CONFIG

    # Create custom filter for TaaOS web applications
    mkdir -p /etc/fail2ban/filter.d
    cat > /etc/fail2ban/filter.d/taaos-web.conf << 'TAAOS_FILTER'
[Definition]
failregex = ^<HOST> -.*"(GET|POST|HEAD).*HTTP.*" (401|403|404|500)
            ^<HOST>.*Failed login.*
            ^<HOST>.*Invalid.*
ignoreregex =
TAAOS_FILTER

    # Enable fail2ban service
    systemctl enable fail2ban || true
    
    echo "[SECURITY] Fail2ban configured with SSH protection enabled"
}

# -----------------------------------------------------------------------------
# SECTION 2: CLAMAV ANTIVIRUS
# -----------------------------------------------------------------------------
setup_clamav() {
    echo "[SECURITY] Installing ClamAV antivirus..."
    
    apt-get install -y clamav clamav-daemon clamav-freshclam
    
    # Stop freshclam service temporarily for initial update
    systemctl stop clamav-freshclam 2>/dev/null || true
    
    # Update virus definitions
    echo "[SECURITY] Updating virus definitions (this may take a while)..."
    freshclam --verbose || echo "[SECURITY] freshclam update failed, will retry on boot"
    
    # Configure ClamAV daemon
    cat > /etc/clamav/clamd.conf.d/taaos.conf << 'CLAMAV_DAEMON' 2>/dev/null || true
# TaaOS ClamAV Configuration
LogFile /var/log/clamav/clamav.log
LogTime yes
LogSyslog yes
LocalSocket /var/run/clamav/clamd.ctl
FixStaleSocket yes
LocalSocketGroup clamav
LocalSocketMode 666
User clamav
ReadTimeout 180
MaxThreads 12
MaxConnectionQueueLength 30
MaxRecursion 16
CLAMAV_DAEMON

    # Create daily scan script
    cat > /etc/cron.daily/clamav-scan << 'CLAMAV_SCAN'
#!/bin/bash
# TaaOS Daily ClamAV Scan
# Scans home directories and logs results

LOGFILE="/var/log/clamav/daily-scan.log"
SCAN_DIR="/home"

echo "=== TaaOS ClamAV Daily Scan ===" >> "$LOGFILE"
echo "Date: $(date)" >> "$LOGFILE"

# Run scan (exclude some directories for performance)
clamscan -r -i \
    --exclude-dir="^/home/.*/\.cache" \
    --exclude-dir="^/home/.*/\.local/share/Trash" \
    --exclude-dir="^/home/.*/.npm" \
    --exclude-dir="^/home/.*/.cargo" \
    "$SCAN_DIR" >> "$LOGFILE" 2>&1

echo "=== Scan Complete ===" >> "$LOGFILE"
echo "" >> "$LOGFILE"
CLAMAV_SCAN

    chmod +x /etc/cron.daily/clamav-scan
    
    # Enable ClamAV services
    systemctl enable clamav-daemon || true
    systemctl enable clamav-freshclam || true
    
    echo "[SECURITY] ClamAV installed with daily scanning configured"
}

# -----------------------------------------------------------------------------
# SECTION 3: LYNIS SECURITY AUDITING
# -----------------------------------------------------------------------------
setup_lynis() {
    echo "[SECURITY] Installing Lynis security auditor..."
    
    apt-get install -y lynis
    
    # Create TaaOS Lynis profile
    mkdir -p /etc/lynis
    cat > /etc/lynis/custom.prf << 'LYNIS_PROFILE'
# =============================================================================
# TaaOS Lynis Custom Profile
# =============================================================================
# Security auditing configuration
# =============================================================================

# Skip certain tests that may not apply to live systems
skip-test=FILE-6310
skip-test=KRNL-5830
skip-test=BOOT-5264

# Plugin settings
plugin=compliance
plugin=docker
plugin=network

# Strict mode
strict=false

# Colors
colors=yes

# Log file
log-file=/var/log/lynis.log

# Report file
report-file=/var/log/lynis-report.dat

# Quick mode (skip some tests for faster audits)
quick=no
LYNIS_PROFILE

    # Create weekly audit script
    cat > /etc/cron.weekly/lynis-audit << 'LYNIS_CRON'
#!/bin/bash
# TaaOS Weekly Lynis Security Audit

LOGFILE="/var/log/lynis-weekly.log"

echo "=== TaaOS Lynis Weekly Audit ===" > "$LOGFILE"
echo "Date: $(date)" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Run Lynis audit
lynis audit system --cronjob --quiet >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "=== Audit Complete ===" >> "$LOGFILE"

# Extract hardening index
echo "" >> "$LOGFILE"
echo "Hardening Index:" >> "$LOGFILE"
grep "Hardening index" /var/log/lynis.log | tail -1 >> "$LOGFILE"
LYNIS_CRON

    chmod +x /etc/cron.weekly/lynis-audit
    
    # Create a quick-audit alias
    cat >> /etc/bash.bashrc << 'LYNIS_ALIAS'

# TaaOS Lynis quick audit
alias security-audit='sudo lynis audit system --quick'
alias security-audit-full='sudo lynis audit system'
LYNIS_ALIAS

    echo "[SECURITY] Lynis installed with weekly audits configured"
}

# -----------------------------------------------------------------------------
# SECTION 4: UNATTENDED UPGRADES (AUTO-UPDATES)
# -----------------------------------------------------------------------------
setup_auto_updates() {
    echo "[SECURITY] Configuring automatic security updates..."
    
    apt-get install -y unattended-upgrades apt-listchanges
    
    # Configure unattended-upgrades
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'UNATTENDED_CONFIG'
// =============================================================================
// TaaOS Unattended Upgrades Configuration
// =============================================================================
// Automatic security updates without user intervention
// =============================================================================

Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    "${distro_id}:${distro_codename}-updates";
};

// Packages to NOT auto-update (blacklist)
Unattended-Upgrade::Package-Blacklist {
    // Kernel updates require reboot, handle manually
    // "linux-";
    // "linux-image";
    // "linux-headers";
};

// Auto-fix interrupted dpkg
Unattended-Upgrade::AutoFixInterruptedDpkg "true";

// Split upgrade to smaller chunks
Unattended-Upgrade::MinimalSteps "true";

// Install updates on shutdown
Unattended-Upgrade::InstallOnShutdown "false";

// Email notifications (optional)
// Unattended-Upgrade::Mail "admin@localhost";
// Unattended-Upgrade::MailReport "on-change";

// Remove unused kernel packages
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

// Remove unused dependencies
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatic reboot if required
Unattended-Upgrade::Automatic-Reboot "false";

// Reboot time (if automatic reboot is enabled)
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Enable SysLog logging
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";

// Only run on AC power
Unattended-Upgrade::OnlyOnACPower "true";

// Skip updates on low disk space
Unattended-Upgrade::Skip-Updates-On-Metered-Connections "true";

// Verbose mode
Unattended-Upgrade::Verbose "false";

// Debug mode
Unattended-Upgrade::Debug "false";
UNATTENDED_CONFIG

    # Configure periodic updates
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'AUTO_UPGRADES'
// TaaOS Auto-Upgrades Schedule
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
AUTO_UPGRADES

    # Enable unattended-upgrades service
    systemctl enable unattended-upgrades || true
    
    # Enable the timer
    systemctl enable apt-daily.timer || true
    systemctl enable apt-daily-upgrade.timer || true
    
    echo "[SECURITY] Automatic security updates configured"
}

# -----------------------------------------------------------------------------
# SECTION 5: ADDITIONAL SECURITY HARDENING
# -----------------------------------------------------------------------------
additional_hardening() {
    echo "[SECURITY] Applying additional security configurations..."
    
    # Secure shared memory
    if ! grep -q "tmpfs /run/shm" /etc/fstab; then
        echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab
    fi
    
    # Create security sysctl configuration
    cat > /etc/sysctl.d/99-taaos-security.conf << 'SYSCTL_SECURITY'
# =============================================================================
# TaaOS Security Hardening - Kernel Parameters
# =============================================================================

# Prevent IP spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable IP source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Ignore ICMP broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Don't send ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Enable SYN cookies (prevent SYN flood attacks)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Disable IPv6 router advertisements
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# Protect against hardlink/symlink attacks
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2

# Restrict dmesg access
kernel.dmesg_restrict = 1

# Restrict kernel pointer access
kernel.kptr_restrict = 2

# Enable ASLR
kernel.randomize_va_space = 2

# Restrict ptrace
kernel.yama.ptrace_scope = 1

# Prevent core dumps for SUID programs
fs.suid_dumpable = 0
SYSCTL_SECURITY

    # Secure SSH configuration
    if [ -f /etc/ssh/sshd_config ]; then
        cat > /etc/ssh/sshd_config.d/taaos-hardening.conf << 'SSH_HARDENING'
# TaaOS SSH Hardening
Protocol 2
PermitRootLogin prohibit-password
MaxAuthTries 3
MaxSessions 5
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
SSH_HARDENING
    fi
    
    echo "[SECURITY] Additional hardening applied"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "[SECURITY] Starting TaaOS Security Hardening..."
    echo ""

    setup_fail2ban
    echo ""
    
    setup_clamav
    echo ""
    
    setup_lynis
    echo ""
    
    setup_auto_updates
    echo ""
    
    additional_hardening
    echo ""

    echo "=============================================="
    echo "  TaaOS Security Hardening - COMPLETE!"
    echo "=============================================="
    echo ""
    echo "  Configured Services:"
    echo "  - Fail2ban: SSH brute-force protection"
    echo "  - ClamAV: Antivirus with daily scans"
    echo "  - Lynis: Weekly security audits"
    echo "  - Unattended-Upgrades: Auto security patches"
    echo ""
    echo "  Commands:"
    echo "  - security-audit       Quick security check"
    echo "  - security-audit-full  Full Lynis audit"
    echo "  - fail2ban-client status  Check banned IPs"
    echo ""
}

# Run main function
main "$@"
