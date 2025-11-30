#!/bin/bash
#
# TaaOS Post-Install Script
# Runs after system installation to configure everything
#

echo "╔══════════════════════════════════════════════════════════╗"
echo "║          TaaOS Post-Installation Setup                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

echo "[1/15] Configuring system..."

# Set hostname
read -p "Enter hostname [taaos]: " hostname
hostname="${hostname:-taaos}"
hostnamectl set-hostname "$hostname"
echo "✓ Hostname set to: $hostname"

# Configure locale
echo "[2/15] Setting up locales..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8
echo "✓ Locale configured"

# Configure timezone
echo "[3/15] Setting timezone..."
timedatectl set-timezone America/New_York  # Change as needed
timedatectl set-ntp true
echo "✓ Timezone set"

# Enable essential services
echo "[4/15] Enabling services..."
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable sddm
systemctl enable taaos-guardian
echo "✓ Services enabled"

# Configure UFW firewall
echo "[5/15] Configuring firewall..."
ufw --force reset
cp /etc/taaos/firewall/ufw.conf /etc/ufw/user.rules
ufw enable
echo "✓ Firewall configured"

# Apply TaaOS theme
echo "[6/15] Applying Rosso Corsa theme..."
taatheme apply rosso-corsa --system-wide
echo "✓ Theme applied"

# Configure GRUB
echo "[7/15] Configuring bootloader..."
cp /usr/share/taaos/branding/grub/* /boot/grub/themes/taaos/
sed -i 's/#GRUB_THEME=.*/GRUB_THEME="\/boot\/grub\/themes\/taaos\/theme.txt"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
echo "✓ GRUB configured"

# Configure Plymouth
echo "[8/15] Configuring boot splash..."
plymouth-set-default-theme taaos
update-initramfs -u
echo "✓ Plymouth configured"

# Set up automatic snapshots
echo "[9/15] Configuring automatic snapshots..."
systemctl enable taaos-snapshot.timer
echo "✓ Snapshots configured"

# Install base packages
echo "[10/15] Installing essential packages..."
taapac sync
taapac install --needed firefox vscodium git docker
echo "✓ Base packages installed"

# Configure Docker
echo "[11/15] Configuring Docker..."
systemctl enable docker
groupadd -f docker
echo "✓ Docker configured"

# Set up developer tools
echo "[12/15] Setting up developer environment..."
# Install common dev packages
taapac install --needed \
    gcc clang rust go python node \
    make cmake ninja gdb valgrind

# Configure Git
git config --system init.defaultBranch main
git config --system pull.rebase false
echo "✓ Developer tools configured"

# Configure Zsh for all users
echo "[13/15] Configuring shell..."
chsh -s /bin/zsh root
cp /etc/skel/.zshrc /root/
echo "✓ Shell configured"

# Set up TaaOS Guardian
echo "[14/15] Initializing security..."
mkdir -p /var/lib/taaos /var/log/taaos
touch /var/log/taaos-guardian.log
chmod 600 /var/log/taaos-guardian.log
systemctl start taaos-guardian
echo "✓ Security initialized"

# Final optimizations
echo "[15/15] Applying optimizations..."

# Enable TRIM for SSD
systemctl enable fstrim.timer

# Configure swappiness  
echo "vm.swappiness=10" >> /etc/sysctl.d/99-taaos.conf

# Apply sysctl optimizations
cat > /etc/sysctl.d/99-taaos-performance.conf << EOF
# TaaOS Performance Optimizations
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
kernel.sched_autogroup_enabled = 1
EOF

sysctl --system
echo "✓ Optimizations applied"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          TaaOS Installation Complete!                   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "System configured with:"
echo "  • Hostname: $hostname"
echo "  • Theme: Rosso Corsa"
echo "  • Firewall: Enabled"
echo "  • Security: TaaOS Guardian running"
echo "  • Snapshots: Automatic (daily)"
echo "  • Desktop: KDE Plasma + Wayland"
echo ""
echo "Next steps:"
echo "  1. Reboot: sudo reboot"
echo "  2. Login with your user account"
echo "  3. Run TaaOS Welcome for tour"
echo "  4. Update system: taapac sync && taapac upgrade"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "TaaOS - Developer power, Ferrari style 🏎️"
echo "═══════════════════════════════════════════════════════════"
