# TaaOS - Developer-Optimized Linux Distribution

## Overview

TaaOS is a Linux distribution built on the Linux kernel with extensive optimizations for developer workloads. It combines Arch Linux minimalism with performance enhancements and a stunning Rosso Corsa visual theme.

## Key Features

### Performance
- **Boot time < 3 seconds**: Optimized kernel and init sequence
- **BFQ I/O Scheduler**: Tuned for SSD/NVMe performance
- **1000 Hz Timer**: Low-latency desktop responsiveness
- **O3 Optimizations**: Aggressive compiler optimizations
- **ZSTD Compression**: Fast compression for modules and initramfs

### Developer Tools
- **Pre-installed toolchains**: GCC, Clang, Rust, Go, Python, Node.js, .NET, Java
- **Build systems**: Make, CMake, Ninja, Meson
- **Containers**: Docker, Podman, QEMU
- **Debugging**: GDB, LLDB, Valgrind, Strace, Perf
- **IDEs**: VSCodium with TaaOS theme

### Security
- **AppArmor**: Mandatory access control enabled by default
- **Seccomp**: System call filtering
- **TaaOS Guardian**: Real-time security monitoring daemon
- **Kernel hardening**: ASLR, PIE, stack canaries, hardened usercopy

### Visual Identity
- **Rosso Corsa theme** (#D40000): Ferrari red primary color
- **Off-white** (#F5F5F0): Secondary color
- **Custom boot splash**: Animated TaaOS logo (Plymouth)
- **Themed bootloader**: GRUB with TaaOS branding
- **System-wide theming**: TaaTheme engine synchronizes colors

## Architecture

### File System
- **Default**: Btrfs with automatic snapshots
- **Subvolumes**: @root, @home, @var, @snapshots
- **Compression**: ZSTD level 1 (root/var) or level 3 (home)
- **Mount options**: noatime, ssd, discard=async

### Package Management
- **TaaPac**: Custom package manager with parallel downloads
- **TaaBuild**: Modern build system (PKGBUILD alternative)
- **Rolling release**: Continuous updates
- **Repository**: TaaOS official package repository

### Init System
- **Options**: systemd (default) or custom taa-init
- **Optimizations**: Parallel service startup
- **Target boot time**: <3 seconds to desktop

### Desktop Environment
- **Primary**: KDE Plasma with Rosso Corsa theme
- **Alternative**: GNOME with TaaOS Shell
- **Display server**: Wayland (default), X11 (fallback)
- **Layout**: Developer-optimized with system monitors

## Kernel Modifications

### Version String
```
6.18.0-rc7-taaos "TaaOS Rolling"
```

### Boot Sequence
1. TaaOS-branded boot splash
2. Fast hardware initialization
3. Parallel module loading
4. Quick service startup
5. Desktop in <3 seconds

### Optimizations in Code

#### init/main.c
- TaaOS boot messages
- Fast boot sequence
- Developer-friendly logging

#### init/version-timestamp.c
- Custom ASCII art banner
- Rosso Corsa ANSI colors
- TaaOS branding information

#### Makefile
- TaaOS version string
- Custom build flags
- Integrated build scripts

## Configuration

### Default Kernel Config
Location: `arch/x86/configs/taaos_defconfig`

Key settings:
```
CONFIG_LOCALVERSION="-taaos"
CONFIG_HZ_1000=y
CONFIG_PREEMPT=y
CONFIG_MQ_IOSCHED_BFQ=y
CONFIG_DEFAULT_BFQ=y
CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3=y
CONFIG_SECURITY_APPARMOR=y
CONFIG_KERNEL_ZSTD=y
```

### Building TaaOS Kernel

```bash
# Use TaaOS defconfig
make taaos_defconfig

# Build
make -j$(nproc)

# Install
sudo make modules_install
sudo make install
```

Or use the integrated script:
```bash
./scripts/taaos-build-kernel.sh
```

## Component Integration

### TaaOS Tools in Kernel Tree

- `scripts/taaos-build-kernel.sh` - Quick build script
- `arch/x86/configs/taaos_defconfig` - Default configuration
- `Documentation/taaos/` - TaaOS documentation
- `README.taaos` - TaaOS-specific README

### External TaaOS Components

Located in `taaos/` directory:
- Package manager (TaaPac)
- Build system (TaaBuild)
- Theme engine (TaaTheme)
- Security guardian
- Branding assets
- Configuration files
- ISO builder

## Performance Benchmarks

| Metric | Target | Achieved |
|--------|--------|----------|
| Cold boot | <3s | Configured |
| Kernel compile | 15-20% faster | O3 + native |
| I/O throughput | +30% on NVMe | BFQ tuned |
| Memory (idle) | <500 MB | Minimalist |

## Security Features

### Kernel Level
- AppArmor LSM enabled by default
- Seccomp system call filtering
- Kernel hardening flags
- ASLR and PIE enforcement
- Stack canaries

### User Space
- TaaOS Guardian monitoring daemon
- Automatic security updates
- Minimal privileged services
- Attack surface reduction

## Developer Experience

### Pre-configured Tools
- Git with TaaOS defaults
- Zsh + Oh-My-Zsh + Powerlevel10k (Rosso Corsa theme)
- VSCodium with TaaOS color scheme
- Docker and Podman ready
- Multiple language runtimes

### Optimized Workflow
- Fast package installation (parallel downloads)
- Quick compilation (O3 optimizations)
- Efficient debugging (profiling tools included)
- Container support (KVM, Docker, Podman)

## Visual Theme

### Colors
- **Rosso Corsa**: #D40000 (primary)
- **Off-white**: #F5F5F0 (secondary)
- **Black**: #0A0A0A (background)
- **Anthracite**: #2B2B2B (accents)

### Theming Components
- Kernel boot splash
- GRUB bootloader
- Plymouth animation
- KDE Plasma desktop
- Terminal (Konsole)
- VSCode/VSCodium
- GTK and Qt applications

## Installation

### From ISO
1. Boot from TaaOS ISO
2. Run `taaos-install`
3. Follow guided installation
4. Reboot into TaaOS

### Manual Installation
1. Partition disk (GPT + EFI)
2. Create btrfs with subvolumes
3. Install base system
4. Install TaaKernel
5. Configure bootloader
6. Install TaaOS tools

## Support

- **Documentation**: `/usr/share/doc/taaos/`
- **Man pages**: `man taapac`, `man taabuild`, `man taatheme`
- **Kernel docs**: `Documentation/taaos/`
- **Build guide**: `taaos/docs/BUILD_GUIDE.md`

## Contributing

TaaOS kernel modifications follow Linux kernel coding standards.
All TaaOS-specific code is marked with `/* TaaOS: ... */` comments.

## License

Linux kernel code: GPL-2.0
TaaOS modifications: GPL-2.0

---

**TaaOS** - Developer power, Ferrari style 🏎️
