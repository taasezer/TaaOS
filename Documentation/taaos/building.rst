# Building TaaOS from Source

This guide explains how to build the complete TaaOS system from this Linux kernel source tree.

## Prerequisites

### Required Tools
- GCC 11+ or Clang 13+
- Make 4.0+
- Bash
- Git
- Python 3.8+
- Flex, Bison
- OpenSSL development files
- ELF utilities
- BC (calculator)
- ZSTD compression tools

### On Debian/Ubuntu
```bash
sudo apt install build-essential libncurses-dev bison flex libssl-dev \
    libelf-dev bc python3 python3-pip zstd squashfs-tools xorriso grub-efi
```

### On Arch Linux
```bash
sudo pacman -S base-devel bc python python-pip zstd squashfs-tools \
    libisoburn grub efibootmgr
```

## Quick Build (Recommended)

```bash
# From kernel source root
./scripts/taaos-build-all.sh
```

This master script will:
1. Configure kernel with `taaos_defconfig`
2. Build TaaKernel with optimizations
3. Create initramfs
4. Prepare TaaOS tools
5. Optionally build bootable ISO

## Manual Build Steps

### 1. Configure Kernel

```bash
# Use TaaOS default configuration
make taaos_defconfig

# Or customize
make menuconfig
```

### 2. Build Kernel

```bash
# Quick build
./scripts/taaos-build-kernel.sh

# Or manually
make -j$(nproc) LOCALVERSION=-taaos
```

### 3. Build Modules

```bash
make -j$(nproc) modules
```

### 4. Create Initramfs

```bash
cd taaos/rootfs/scripts
./create-initramfs.sh
```

### 5. Build ISO

```bash
cd taaos/iso/scripts
sudo ./build-iso.sh
```

## Installing TaaOS Kernel

### On Running System

```bash
# Install modules
sudo make modules_install

# Install kernel
sudo make install

# Update bootloader
sudo update-grub  # Debian/Ubuntu
# or
sudo grub-mkconfig -o /boot/grub/grub.cfg  # Arch
```

### Custom Installation

```bash
# Copy kernel
KERNEL_VERSION=$(make kernelrelease)
sudo cp arch/x86/boot/bzImage /boot/vmlinuz-${KERNEL_VERSION}

# Copy initramfs (if created)
sudo cp taaos/rootfs/output/initramfs-*.img /boot/

# Update GRUB configuration manually
sudo nano /etc/grub.d/40_custom
# Add TaaOS entry

sudo update-grub
```

## Building TaaOS Tools

### TaaPac (Package Manager)

```bash
cd taaos/taapac/src
chmod +x taapac taabuild

# Test
./taapac --version
./taabuild --version
```

### TaaTheme (Theme Engine)

```bash
cd taaos/taatheme/engine
chmod +x taatheme

# Test
./taatheme list
```

### TaaOS Guardian (Security)

```bash
cd taaos/security/guardian
chmod +x taaos-guardian

# Test
./taaos-guardian status
```

## Configuration Options

### Kernel Build Options

```bash
# Use different optimization
make CFLAGS="-O3 -march=native"

# Enable more debugging
make menuconfig
# Navigate to: Kernel hacking -> Compile-time checks and compiler options
```

### Custom Branding

Edit these files to customize:
- `init/version-timestamp.c` - Boot banner
- `Makefile` - Version string (line 5-6)
- `arch/x86/configs/taaos_defconfig` - Default config

### Performance Tuning

Edit `arch/x86/configs/taaos_defconfig`:
```
# Change timer frequency
CONFIG_HZ_1000=y  # or CONFIG_HZ_300=y for battery

# Change I/O scheduler  
CONFIG_DEFAULT_BFQ=y  # or CONFIG_DEFAULT_MQ_DEADLINE=y

# Change preemption
CONFIG_PREEMPT=y  # or CONFIG_PREEMPT_VOLUNTARY=y
```

## Testing

### In QEMU

```bash
# Test kernel directly
qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -kernel arch/x86/boot/bzImage \
    -append "console=ttyS0" \
    -nographic

# Test ISO
qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -cdrom taaos/iso/output/taaos-rolling-x86_64.iso \
    -boot d \
    -enable-kvm
```

### In VirtualBox

1. Create new VM (Linux, Arch Linux 64-bit)
2. Attach TaaOS ISO
3. Boot and test

## Customizing TaaOS

### Adding Packages

Edit `taaos/packages/default-packages.txt`:
```
# Add your packages
my-favorite-tool
another-package
```

### Changing Theme

Default theme is Rosso Corsa. To add new theme:

1. Create theme file in `taaos/taatheme/themes/`
2. Edit `taaos/taatheme/engine/taatheme` to add preset
3. Rebuild

### Modifying Boot Splash

Edit `taaos/branding/plymouth/taaos.plymouth` and rebuild.

## Troubleshooting

### Build Errors

```bash
# Clean build
make mrproper
make taaos_defconfig
make -j$(nproc)

# Check dependencies
./scripts/check-dependencies.sh
```

### Module Errors

```bash
# Rebuild modules cleanly
make modules_clean
make -j$(nproc) modules
sudo make modules_install
```

### Boot Issues

```bash
# Check kernel command line
cat /proc/cmdline

# View boot log
dmesg | less

# Check initramfs
lsinitrd /boot/initramfs-*.img
```

## Advanced Build Options

### Cross-Compilation

```bash
# For ARM64
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- taaos_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
```

### Debug Build

```bash
# Enable debug symbols
scripts/config --enable DEBUG_INFO
scripts/config --enable DEBUG_INFO_DWARF4
scripts/config --disable DEBUG_INFO_REDUCED
make -j$(nproc)
```

### Minimal Build

```bash
# Disable debugging
scripts/config --disable DEBUG_KERNEL
scripts/config --disable DEBUG_INFO
make -j$(nproc)
```

## Continuous Integration

### Automated Builds

```bash
# CI/CD script
#!/bin/bash
cd /path/to/kernel
git pull
./scripts/taaos-build-all.sh
# Deploy ISO
```

### Docker Build Environment

```dockerfile
FROM archlinux:latest
RUN pacman -Syu --noconfirm base-devel
COPY . /kernel
WORKDIR /kernel
RUN ./scripts/taaos-build-all.sh
```

## Performance Optimization

### Build Time Optimization

```bash
# Use ccache
export CC="ccache gcc"
export CXX="ccache g++"
make -j$(nproc)

# Parallel linking
export LDFLAGS="-Wl,--threads"
```

### Binary Optimization

```bash
# Link-time optimization (experimental)
scripts/config --enable LTO_CLANG_THIN
make -j$(nproc) LLVM=1
```

## Documentation

After building, documentation is available:
- Kernel docs: `Documentation/taaos/`
- TaaOS docs: `taaos/docs/`
- Man pages: Will be installed to `/usr/share/man/`

## Getting Help

- Read `README.taaos` in kernel root
- Check `Documentation/taaos/overview.rst`
- View `taaos/README.md` for complete documentation
- See `taaos/docs/QUICKSTART.md` for quick start

## Next Steps

After building:
1. Install and boot kernel
2. Install TaaOS tools to `/usr/bin/`
3. Apply TaaOS theme
4. Install default packages
5. Enjoy TaaOS!

---

**TaaOS** - Developer power, Ferrari style 🏎️
