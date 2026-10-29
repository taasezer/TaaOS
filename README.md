# TaaOS

TaaOS is a deterministic, high-performance Linux distribution built on the Debian (Trixie) base and engineered specifically for software developers, systems engineers, data scientists, and DevOps professionals.

Instead of shipping bloated background daemons that consume memory at idle, TaaOS combines a custom-compiled mainline Linux kernel (`-taaos`), a **Systemd-Free** init and service architecture (**SysVinit PID 1 + OpenRC + elogind**), a zero-lag desktop environment (**XFCE4 + Polybar + Rofi + custom GTK3 utilities**), a local natural-language AI engine (**TaaNOS**), and an on-demand **Modular CRUD Developer Suite** (`taaos-*`).

---

## Core Architecture

### 1. Systemd-Free Init and Parallel Service Management
*   **PID 1 (`sysvinit-core`)**: Ultra-lightweight, deterministic process initialization without monolithic init overhead.
*   **Service Manager (`openrc`)**: Parallel dependency-based service execution (`rc_parallel="YES"`), delivering fast boot times and minimal idle RAM consumption.
*   **Session and Seat Management (`elogind` + `libpam-elogind` + `dbus-x11`)**: Full X11, Polkit, audio, display, and power management compatibility without `systemd-logind`.
*   **Transparent `systemctl` Compatibility Bridge (`/usr/local/bin/systemctl`)**: Automatically translates `systemctl` commands (`start`, `stop`, `restart`, `reload`, `status`, `enable`, `disable`, `is-active`, `is-enabled`, `reboot`, `poweroff`, `suspend`) into native OpenRC (`rc-service` / `rc-update`) and SysVinit operations so existing scripts, developer workflows, and TaaNOS commands work seamlessly.
*   **APT Protection**: `systemd` and `systemd-sysv` are pinned to `-1` priority in `/etc/apt/preferences.d/99-systemd-free` to prevent accidental reinstallation during future package operations.

### 2. Custom Mainline Linux Kernel (`-taaos`)
*   Compiled from mainline Linux kernel source during the ISO build (`compile_kernel.sh`).
*   Tuned for low-latency desktop responsiveness, workstation throughput, virtualization (`KVM`, `virtio`, `vboxguest`, `vboxvideo`, `vmwgfx`), modern filesystems (`ext4`, `btrfs`, `xfs`, `f2fs`), and hardware error reporting (`EDAC` / ECC memory).
*   Kernel runtime parameters (`/etc/sysctl.d/99-taaos-performance.conf`):
    *   `vm.swappiness = 10`
    *   `fs.inotify.max_user_watches = 524288`
    *   `vm.dirty_ratio = 10` and `vm.dirty_background_ratio = 5`
    *   `net.core.rmem_max = 16777216` and `net.core.wmem_max = 16777216`

### 3. Desktop Environment and Visual Interface
*   **Window Manager (`xfwm4`)**: Uses XFWM4's native C double-buffered compositor (`use_compositing = true`, `vblank_mode = off`) by default for tear-free, trail-free 60 FPS window dragging in both virtual machines and bare-metal hardware. Optional `picom` GLX compositor can be toggled anytime from the Appearance Studio.
*   **Top Bar (`polybar`)**: Native top bar displaying an application launcher trigger, numbered workspaces (`1 2 3 4`), active window title, center clock, audio volume, screen brightness, network/Bluetooth/settings quick tray, live RAM/CPU telemetry, and power menu.
*   **Application Launcher (`rofi`)**: Keyboard-driven (`Super+Space`, `Super+D`, `Alt+F1`) application and command runner.
*   **Unified Light and Dark Mode**: Pre-installed with `Orchis` (`Orchis-Red-Dark`, `Orchis-Red-Light`, and accent variants) and `Papirus` (`Papirus-Dark`, `Papirus-Light`) icon themes. Switching between Light Mode and Dark Mode dynamically updates GTK3 applications, XFWM4 window borders, Polybar, Rofi, XFCE4 Terminal, the Radial Wheel, and the Control Center.
*   **Plymouth Boot Splash**: Dynamic resolution-aware boot splash (`taaos.script`) that automatically re-centers the TaaOS emblem and progress bar across KMS/DRM resolution changes.

---

## TaaOS Custom Desktop Applications and Utilities

All TaaOS graphical and CLI utilities automatically detect the system locale (`LANG` / `LC_ALL`), providing native Turkish (`tr_TR`) and English (`en_US`) interfaces, with manual override support via `--lang=tr` or `--lang=en`.

| Command | Description |
| :--- | :--- |
| `taaos-control-center` | Top-right Bento-Grid quick settings flyout. Includes 2x2 quick tiles (Wi-Fi/Network, Bluetooth, Dark/Light Mode toggle, Appearance Studio), full-width Volume and Brightness sliders, Audio Mixer button, Display Auto-Fit button, and quick launchers for TaaNOS, Radial Wheel, `btop`, and session logout. Also provides CLI flags (`--brightness-get`, `--brightness-up`, `--brightness-down`). |
| `taaos-appearance` | Graphical and CLI Appearance Studio. Switches between Dark Mode and Light Mode (`taaos-appearance dark`, `taaos-appearance light`, `taaos-appearance toggle-mode`), applies 5 accent palettes (`red`, `cyan`, `purple`, `emerald`, `amber`), and switches between Performance Mode (XFWM4 native compositor) and Glass Mode (Picom compositor). |
| `taaos-theme` | Command-line theme controller (`taaos-theme dark`, `taaos-theme light`, `taaos-theme toggle`, `taaos-theme status`, `taaos-theme gui`). |
| `taaos-wheel` | Quick-access Radial Application Wheel (`580x580` Cairo/GTK3 canvas). Opens at the cursor position when holding the **Right Mouse Button** on the empty desktop (`--daemon`) or via `taaos-wheel`. Configurable with `taaos-wheel --config` to add, remove, or reorder favorite commands. |
| `taaos-display-watcher` | Background display daemon that monitors DRM hotplug events (`udev`) and `xrandr` preferred modes. Automatically resizes the desktop in VirtualBox (`VMSVGA` / `VBoxVGA`), VMware, and QEMU/SPICE, and reloads both the wallpaper and Polybar on resolution changes. |
| `taaos-display-fix` | Instant CLI/GUI helper that probes the connected display output, switches to the preferred resolution, reloads the desktop wallpaper, and restarts Polybar. |
| `taaos-install` | Graphical OS installer wrapper for **Calamares**. Automatically releases swap locks, dynamically detects the live `filesystem.squashfs` path, and launches Calamares with TaaOS high-contrast dark styling. |

---

## Modular Developer Suites (On-Demand CRUD Engine)

To keep the base operating system lean while giving engineers instant access to heavy toolchains, TaaOS provides five modular CRUD (`status`, `install`, `update`, `remove`, `help`) suites. Running any suite without arguments opens an interactive bilingual menu.

### 1. `taaos-backend` — Backend and Database Toolchain
Manages server-side programming languages, package managers, and database clients:
*   **Targets**:
    *   `python`: Python 3, `pip`, `venv`, `uv` (Rust-based fast package/environment manager), `FastAPI`, `Uvicorn`
    *   `node`: Node.js LTS, `npm`, `pnpm`, `tsx` (zero-config TypeScript runner)
    *   `go`: Go compiler (`golang-go`) and official language server (`gopls`)
    *   `rust`: Rust compiler (`rustc`) and `cargo`
    *   `db`: PostgreSQL client (`psql`), Redis CLI (`redis-cli`), and SQLite 3 (`sqlite3`)
    *   `all`: Installs or updates the complete backend stack
*   **Examples**:
    ```bash
    taaos-backend status
    taaos-backend install python
    taaos-backend install db
    taaos-backend update all
    taaos-backend remove go
    ```

### 2. `taaos-frontend` — Modern Web and Desktop UI Toolchain
Manages JavaScript/TypeScript runtimes, bundlers, CSS compilers, and hybrid desktop frameworks:
*   **Targets**:
    *   `bun`: Bun all-in-one JavaScript/TypeScript runtime and bundler
    *   `pnpm`: Fast hard-link package manager
    *   `yarn`: Classic Yarn package manager
    *   `vite`: Vite frontend build tool and dev server
    *   `tailwind`: Standalone Tailwind CSS CLI compiler
    *   `tauri`: Rust-based Tauri desktop application prerequisites (`libwebkit2gtk`, `cargo-tauri`)
    *   `all`: Installs the complete frontend stack
*   **Examples**:
    ```bash
    taaos-frontend status
    taaos-frontend install bun
    taaos-frontend install vite
    taaos-frontend remove yarn
    ```

### 3. `taaos-devops` — Containers, Kubernetes, and Infrastructure as Code
Manages container engines, cluster orchestration tools, and cloud provisioning utilities:
*   **Targets**:
    *   `docker`: Docker Engine (`docker.io`), `docker-compose`, `lazydocker` TUI, and `ctop`
    *   `k8s`: Kubernetes CLI (`kubectl`), `helm`, and `k9s` cluster TUI
    *   `terraform`: HashiCorp Terraform CLI
    *   `ansible`: Ansible automation engine
    *   `aws`: AWS CLI
    *   `all`: Installs the complete DevOps stack
*   **Examples**:
    ```bash
    taaos-devops status
    taaos-devops install docker
    taaos-devops install k8s
    taaos-devops remove terraform
    ```

### 4. `taaos-ai` — Isolated AI and Data Science Laboratory
Creates and manages a dedicated Python virtual environment at `~/.taaos/ai-env` so heavy machine learning libraries never pollute or break system Python packages:
*   **Targets**:
    *   `env`: Creates the isolated `~/.taaos/ai-env` virtual environment
    *   `pytorch`: Installs PyTorch (`torch`, `torchvision`, `torchaudio`) inside `~/.taaos/ai-env`
    *   `datascience`: Installs `numpy`, `pandas`, `scipy`, `scikit-learn`, `matplotlib`, `seaborn`
    *   `jupyter`: Installs `jupyterlab` and `notebook`
    *   `ollama`: Installs and configures the local Ollama LLM server
    *   `shell`: Activates the `~/.taaos/ai-env` shell environment
    *   `all`: Installs the complete AI and Data Science stack
*   **Examples**:
    ```bash
    taaos-ai status
    taaos-ai install all
    taaos-ai shell
    ```

### 5. `taaos-linux` — Kernel Headers, eBPF Profiling, and Sysctl Tuning
Manages low-level systems engineering, kernel module building, and performance profiles:
*   **Targets**:
    *   `headers`: Linux kernel headers, `dkms`, `build-essential`, `llvm`, `clang`
    *   `profiling`: `linux-perf`, `bpftrace`, `valgrind`, `strace`, `ltrace`, `gdb`
    *   `telemetry`: `inxi`, `lshw`, `sysstat` (`iostat`, `mpstat`, `pidstat`, `sar`)
    *   `tune`: Applies kernel `sysctl` optimization profiles (`desktop`, `server`, `latency`)
    *   `all`: Installs all kernel and systems engineering tools
*   **Examples**:
    ```bash
    taaos-linux status
    taaos-linux install profiling
    taaos-linux tune latency
    ```

---

## System Administration and Maintenance Commands

| Command | Description |
| :--- | :--- |
| `taaos-doctor` | Runs a comprehensive system diagnostic: OS identity, kernel version, CPU/RAM/Disk usage, active services, network connectivity, and installation status of all `taaos-*` suites. |
| `taaos-update` | Performs system-wide APT updates, repairs broken dependencies (`dpkg --configure -a`), updates installed `taaos-*` modules, and refreshes the TaaNOS binary. |
| `taaos-clean` | Cleans APT package caches, removes orphaned packages (`autoremove`), clears old logs, and frees temporary build/thumbnail caches. |
| `taaos-help` | Displays the bilingual quick reference guide for all TaaOS commands and shortcuts. |
| `taaos-drivers` | Detects PCI/USB hardware and assists with graphics, network, and firmware driver installation. |
| `taaos-harden` | Applies security hardening rules (UFW firewall, sysctl network protections, SSH hardening). |
| `taaos-rescue` | Emergency system repair utility for bootloader (GRUB), fstab, initramfs, and package database recovery. |
| `taaos-boot-analyze` | Inspects boot service startup order and active OpenRC runlevels. |
| `taaos-dll-handler` | Registers, unregisters, inspects, or executes Windows `.dll` libraries via Wine (`taaos-dll-handler <file.dll> [register\|unregister\|info\|run]`). |
| `taaos-node-repl` | Launches an interactive Node.js REPL terminal session. |
| `taaos-create-persistent-usb` | Formats and configures a Live USB drive with an encrypted or standard persistence partition. |
| `taaos-setup-persistence` | Configures `persistence.conf` on a target partition for Live USB state retention. |

---

## TaaNOS — Local Natural Language AI Engine

TaaNOS (`taanos` or `ai`) is TaaOS's native terminal AI assistant and natural-language command engine:
*   **Offline Instant Match (0ms)**: Common system administration requests (updating packages, checking disk space, listing open ports, checking memory, managing services) are matched deterministically offline in 0ms without waiting for an LLM.
*   **Local LLM Integration (Ollama)**: Complex queries and code generation requests connect automatically to the local Ollama pipeline (starting the Ollama daemon automatically if not already running) and select the active installed model dynamically.
*   **Interactive TUI and Single-Shot CLI**:
    *   Run `taanos` to open the full-screen interactive terminal UI.
    *   Run `taanos "check open ports"` or `ai "list largest files"` for direct command translation and execution.
    *   Run `taanos status` or `taanos model` to inspect or switch active local models.
*   **Safety Guardrails**: Two-tier command verification blocks destructive root-filesystem operations (`rm -rf /`, fork bombs, raw disk wipes) and requests explicit confirmation before running privileged modifications.

---

## Services and Runlevel Design

TaaOS separates core desktop services from heavy developer daemons so the system boots rapidly and stays cool and quiet until heavy tools are actually needed.

### Core Services (Enabled at Boot in OpenRC `default` Runlevel)
*   `dbus`: System message bus
*   `elogind`: Desktop seat, session, and power management
*   `network-manager`: Wired and Wi-Fi network management
*   `lightdm`: Display manager and graphical login
*   `plymouth`: Boot splash manager
*   `chrony`: Fast NTP network time synchronization (`makestep 1.0 -1`)
*   `zramswap`: Compressed RAM swap (`50%` of RAM with `zstd` compression)
*   `earlyoom`: Proactive out-of-memory protection that prevents desktop freezes under heavy compile/AI loads
*   `ufw`: Uncomplicated Firewall

### On-Demand Services (Disabled at Boot for Instant Startup)
Heavy daemons are pre-configured not to run at boot and can be started anytime via `rc-service <name> start` or `sudo systemctl start <name>`:
*   `docker` and `containerd` (Container engine)
*   `libvirtd` and `virtlogd` (KVM/QEMU virtualization daemon)
*   `cups` and `cups-browsed` (Printing subsystem)
*   `bluetooth` (Bluetooth stack — started on demand or from Control Center)
*   `rasdaemon` (ECC memory hardware error daemon for server boards)
*   `fail2ban` and `clamav-daemon` (Security daemons)

---

## Pre-Installed Base Packages and Shell Environment

*   **Modern Rust/C CLI Replacements**:
    *   `fastfetch` (TaaOS custom ASCII logo with line-wrap protection and hardware summary)
    *   `bat` / `batcat` (`cat` alias with syntax highlighting)
    *   `eza` / `lsd` (`ls`, `ll`, `tree` aliases with file icons)
    *   `ripgrep` (`rg` fast search)
    *   `fzf` (Fuzzy finder with `Ctrl+R` history search)
    *   `zoxide` (Smart directory jumper)
    *   `btop` and `htop` (Interactive system monitors)
*   **Shells and Editors**: Bash (default with TaaOS aliases and safety barriers), Zsh (with `zsh-autosuggestions` and `zsh-syntax-highlighting`), Neovim, Vim, Micro, Nano.
*   **Safety Barriers (`/etc/profile.d/taaos-safety.sh`)**:
    *   Intercepts recursive `rm` calls targeting critical root paths (`/`, `/etc`, `/usr`, `/boot`, `/home`, `/var`) and blocks execution.
    *   Intercepts `dd` writes targeting physical block devices (`/dev/sd*`, `/dev/nvme*`, `/dev/vd*`) and requires explicit confirmation.
    *   Detects and blocks shell fork bombs.

---

## Building TaaOS

TaaOS builds inside an isolated Docker container so the host system remains completely untouched.

### 1. Build Full Bootable ISO (`TaaOS.iso`)
```bash
./build.sh
```
The build pipeline performs the following phases automatically:
1.  Builds the `taaos-builder:torvalds` Docker image (Debian Trixie environment).
2.  Injects package lists (`config/package-lists/*.list.chroot`), hooks (`config/hooks/live/*.hook.chroot`), scripts (`scripts/`), and rootfs overlays (`config/includes.chroot/`).
3.  Injects the local `taanos` binary from `../TaaNOS/bin/` if present.
4.  Compiles the custom mainline Linux kernel (`compile_kernel.sh`) and packages it into `.deb` archives.
5.  Runs `live-build` (`lb build`) to bootstrap the Debian Trixie rootfs, install all packages, execute hooks `00` through `99` (including `98-systemd-free.hook.chroot`), and package the hybrid UEFI/BIOS `TaaOS.iso`.

### 2. Build WSL Terminal Edition (`TaaOS-WSL.tar.gz`)
```bash
./build_wsl.sh
```
Generates a lightweight, zero-bloat WSL2 distribution tarball (`TaaOS-WSL.tar.gz`) with the TaaOS CLI environment, `fastfetch` branding, Systemd-Free configuration (`systemd=false` in `/etc/wsl.conf`), first-boot user setup wizard (`taaos-wsl-setup`), and the complete `taaos-*` Modular CRUD Developer Suite.

---
---

# TaaOS (Türkçe)

TaaOS; Debian (Trixie) altyapısı üzerine inşa edilmiş, yazılım geliştiriciler, sistem mühendisleri, veri bilimciler ve DevOps uzmanları için tasarlanmış deterministik ve yüksek performanslı bir Linux dağıtımıdır.

Boşta bellek tüketen ağır arka plan servislerini varsayılan olarak çalıştırmak yerine; özel derlenmiş ana hat (mainline) Linux çekirdeği (`-taaos`), **Systemd-Free** başlatma ve servis mimarisi (**SysVinit PID 1 + OpenRC + elogind**), sıfır gecikmeli masaüstü ortamı (**XFCE4 + Polybar + Rofi + özel GTK3 araçları**), yerel doğal dil yapay zeka motoru (**TaaNOS**) ve isteğe bağlı **Modüler CRUD Geliştirici Yığını** (`taaos-*`) ile birlikte gelir.

---

## Temel Mimari

### 1. Systemd-Free Başlatma ve Paralel Servis Yönetimi
*   **PID 1 (`sysvinit-core`)**: Monolitik init yükü olmadan deterministik ve ultra hafif süreç başlatma.
*   **Servis Yöneticisi (`openrc`)**: Bağımlılık grafiğine dayalı paralel servis başlatma (`rc_parallel="YES"`) sayesinde çok hızlı açılış süresi ve düşük boşta RAM kullanımı.
*   **Oturum ve Güç Yönetimi (`elogind` + `libpam-elogind` + `dbus-x11`)**: `systemd-logind` gerektirmeden tam X11, Polkit, ses, ekran ve güç yönetimi uyumluluğu.
*   **Şeffaf `systemctl` Uyumluluk Köprüsü (`/usr/local/bin/systemctl`)**: Standart `systemctl` komutlarını (`start`, `stop`, `restart`, `reload`, `status`, `enable`, `disable`, `is-active`, `is-enabled`, `reboot`, `poweroff`, `suspend`) arka planda otomatik olarak OpenRC (`rc-service` / `rc-update`) ve SysVinit komutlarına çevirir; böylece mevcut betikler ve kullanıcı alışkanlıkları kesintisiz çalışır.
*   **APT Koruması**: `/etc/apt/preferences.d/99-systemd-free` üzerinden `systemd` ve `systemd-sysv` paketleri `-1` öncelikle engellenmiştir; gelecekteki paket kurulumları yanlışlıkla `systemd` yükleyemez.

### 2. Özel Derlenmiş Linux Çekirdeği (`-taaos`)
*   ISO derleme sürecinde (`compile_kernel.sh`) ana hat Linux çekirdek kaynağından özel olarak derlenir.
*   Düşük gecikmeli masaüstü tepkiselliği, sanallaştırma (`KVM`, `virtio`, `vboxguest`, `vboxvideo`, `vmwgfx`), modern dosya sistemleri (`ext4`, `btrfs`, `xfs`, `f2fs`) ve donanım hata raporlama (`EDAC` / ECC bellek) için optimize edilmiştir.
*   Çekirdek çalışma zamanı parametreleri (`/etc/sysctl.d/99-taaos-performance.conf`):
    *   `vm.swappiness = 10`
    *   `fs.inotify.max_user_watches = 524288`
    *   `vm.dirty_ratio = 10` ve `vm.dirty_background_ratio = 5`
    *   `net.core.rmem_max = 16777216` ve `net.core.wmem_max = 16777216`

### 3. Masaüstü Ortamı ve Görsel Arayüz
*   **Pencere Yöneticisi (`xfwm4`)**: Varsayılan olarak XFWM4'ün yerleşik C tabanlı çift tamponlu (double-buffered) kompozitörünü (`use_compositing = true`, `vblank_mode = off`) kullanır. Hem VirtualBox gibi sanal makinelerde hem gerçek donanımda pencere sürüklerken iz bırakmayan, yırtılmasız 60 FPS akıcılık sağlar. İsteğe bağlı `picom` GLX kompozitörü Görünüm Stüdyosu içinden açılabilir.
*   **Üst Bar (`polybar`)**: Uygulama başlatıcı, numaralı çalışma alanları (`1 2 3 4`), aktif pencere başlığı, merkezi saat, ses seviyesi, ekran parlaklığı, ağ/Bluetooth/ayarlar hızlı tepsi ikonları, anlık RAM/CPU kullanımı ve güç menüsünü barındırır.
*   **Uygulama Başlatıcı (`rofi`)**: Klavye odaklı (`Super+Space`, `Super+D`, `Alt+F1`) hızlı uygulama ve komut başlatıcı.
*   **Bütünleşik Aydınlık ve Karanlık Mod (`Light / Dark Mode`)**: `Orchis` (`Orchis-Red-Dark`, `Orchis-Red-Light` ve vurgu varyantları) ile `Papirus` (`Papirus-Dark`, `Papirus-Light`) ikon temaları yüklü gelir. Aydınlık ve Karanlık mod geçişlerinde GTK3 uygulamaları, XFWM4 pencere başlıkları, Polybar, Rofi, XFCE4 Terminal, Hızlı Erişim Çarkı ve Hızlı Ayarlar paneli eşzamanlı olarak güncellenir.
*   **Plymouth Açılış Ekranı**: Ekran çözünürlüğü değişimlerini dinamik olarak algılayan ve TaaOS logosu ile ilerleme çubuğunu her çözünürlükte tam merkeze hizalayan açılış ekranı (`taaos.script`).

---

## TaaOS Özel Masaüstü Uygulamaları ve Araçları

Tüm TaaOS grafiksel ve terminal araçları sistem dilini (`LANG` / `LC_ALL`) otomatik tanır; Türkçe bölgede Türkçe, diğer bölgelerde İngilizce çalışır (`--lang=tr` veya `--lang=en` ile manuel seçilebilir).

| Komut | Açıklama |
| :--- | :--- |
| `taaos-control-center` | Sağ üstte açılan başlıksız Bento-Grid hızlı ayarlar paneli. 2x2 hızlı geçiş kartları (Wi-Fi/Ağ, Bluetooth, Karanlık/Aydınlık Mod geçişi, Görünüm Stüdyosu), tam genişlikte Ses ve Parlaklık sürgüleri, Ses Karıştırıcısı butonu, Ekranı Otomatik Sığdır butonu ve TaaNOS, Çark, `btop` ile oturum kapatma kısayollarını içerir. Ayrıca Polybar için `--brightness-get`, `--brightness-up`, `--brightness-down` parametrelerini destekler. |
| `taaos-appearance` | Grafiksel ve CLI Görünüm Stüdyosu. Karanlık Mod ve Aydınlık Mod geçişini (`taaos-appearance dark`, `taaos-appearance light`, `taaos-appearance toggle-mode`), 5 farklı vurgu rengini (`red`, `cyan`, `purple`, `emerald`, `amber`) ve Performans Modu (XFWM4) ile Cam Efekt Modu (Picom) arasındaki geçişi yönetir. |
| `taaos-theme` | Terminal tabanlı tema değiştirici (`taaos-theme dark`, `taaos-theme light`, `taaos-theme toggle`, `taaos-theme status`, `taaos-theme gui`). |
| `taaos-wheel` | Hızlı Erişim Uygulama Çarkı (`580x580` Cairo/GTK3). Boş masaüstünde **Sağ Tık** basılı tutulduğunda (`--daemon`) veya `taaos-wheel` komutuyla imleç merkezinde açılır. `taaos-wheel --config` ile çarktaki uygulamalar eklenip çıkarılabilir. |
| `taaos-display-watcher` | Arka planda DRM hotplug (`udev`) olaylarını ve `xrandr` tercih edilen çözünürlüklerini izleyen servis. VirtualBox (`VMSVGA` / `VBoxVGA`), VMware ve QEMU/SPICE ortamlarında pencere boyutu değiştiğinde çözünürlüğü otomatik ayarlar, duvar kağıdını ve Polybar'ı yeni boyuta göre yeniler. |
| `taaos-display-fix` | Bağlı ekran çıkışını tarayarak tercih edilen çözünürlüğe geçiren, duvar kağıdını ve üst barı anında yeniden ölçeklendiren yardımcı komut. |
| `taaos-install` | **Calamares** kurulum aracı sarmalayıcısı. Hedef disk üzerindeki takas (swap) kilitlerini serbest bırakır, canlı `filesystem.squashfs` imajını dinamik olarak bulur ve yüksek kontrastlı TaaOS karanlık temasıyla kurulumu başlatır. |

---

## Modüler Geliştirici Yığını (İsteğe Bağlı CRUD Motoru)

Temel işletim sistemini hafif tutarken geliştiricilerin ağır araç setlerine tek komutla ulaşabilmesi için 5 adet modüler CRUD (`status`, `install`, `update`, `remove`, `help`) aracı bulunur. Herhangi bir komut parametresiz çalıştırıldığında etkileşimli menü açılır.

### 1. `taaos-backend` — Backend ve Veritabanı Yığını
Sunucu tarafı programlama dillerini, paket yöneticilerini ve veritabanı istemcilerini yönetir:
*   **Hedefler (`target`)**:
    *   `python`: Python 3, `pip`, `venv`, `uv` (Rust tabanlı hızlı paket ve ortam yöneticisi), `FastAPI`, `Uvicorn`
    *   `node`: Node.js LTS, `npm`, `pnpm`, `tsx` (TypeScript yürütücüsü)
    *   `go`: Go derleyicisi (`golang-go`) ve resmi dil sunucusu (`gopls`)
    *   `rust`: Rust derleyicisi (`rustc`) ve `cargo`
    *   `db`: PostgreSQL istemcisi (`psql`), Redis CLI (`redis-cli`) ve SQLite 3 (`sqlite3`)
    *   `all`: Tüm backend yığınını kurar veya günceller
*   **Örnek Kullanım**:
    ```bash
    taaos-backend status
    taaos-backend install python
    taaos-backend install db
    taaos-backend update all
    taaos-backend remove go
    ```

### 2. `taaos-frontend` — Modern Web ve Masaüstü UI Yığını
JavaScript/TypeScript çalışma zamanlarını, paketleyicileri, CSS derleyicilerini ve hibrit masaüstü çatılarını yönetir:
*   **Hedefler (`target`)**:
    *   `bun`: Bun hepsi-bir-arada JS/TS çalışma zamanı ve paketleyici
    *   `pnpm`: Hızlı hard-link tabanlı paket yöneticisi
    *   `yarn`: Klasik Yarn paket yöneticisi
    *   `vite`: Vite geliştirme sunucusu ve derleme aracı
    *   `tailwind`: Bağımsız Tailwind CSS CLI derleyicisi
    *   `tauri`: Rust tabanlı Tauri masaüstü uygulama geliştirme bağımlılıkları (`libwebkit2gtk`, `cargo-tauri`)
    *   `all`: Tüm frontend yığınını kurar
*   **Örnek Kullanım**:
    ```bash
    taaos-frontend status
    taaos-frontend install bun
    taaos-frontend install vite
    taaos-frontend remove yarn
    ```

### 3. `taaos-devops` — Konteyner, Kubernetes ve Bulut Altyapı Yığını
Konteyner motorlarını, küme orkestrasyon araçlarını ve Kod Olarak Altyapı (IaC) bileşenlerini yönetir:
*   **Hedefler (`target`)**:
    *   `docker`: Docker Engine (`docker.io`), `docker-compose`, `lazydocker` TUI ve `ctop`
    *   `k8s`: Kubernetes CLI (`kubectl`), `helm` ve `k9s` terminal arayüzü
    *   `terraform`: HashiCorp Terraform CLI
    *   `ansible`: Ansible otomasyon motoru
    *   `aws`: AWS CLI
    *   `all`: Tüm DevOps araçlarını kurar
*   **Örnek Kullanım**:
    ```bash
    taaos-devops status
    taaos-devops install docker
    taaos-devops install k8s
    taaos-devops remove terraform
    ```

### 4. `taaos-ai` — İzole Yapay Zeka ve Veri Bilimi Laboratuvarı
Ağır makine öğrenimi kütüphanelerinin sistem Python paketlerini bozmaması için `~/.taaos/ai-env` dizininde izole bir sanal ortam oluşturur ve yönetir:
*   **Hedefler (`target`)**:
    *   `env`: `~/.taaos/ai-env` izole sanal ortamını oluşturur
    *   `pytorch`: Sanal ortam içine PyTorch (`torch`, `torchvision`, `torchaudio`) kurar
    *   `datascience`: `numpy`, `pandas`, `scipy`, `scikit-learn`, `matplotlib`, `seaborn` kurar
    *   `jupyter`: `jupyterlab` ve `notebook` kurar
    *   `ollama`: Yerel Ollama LLM sunucusunu kurar ve yapılandırır
    *   `shell`: `~/.taaos/ai-env` sanal ortam kabuğunu etkinleştirir
    *   `all`: Tüm yapay zeka ve veri bilimi yığınını kurar
*   **Örnek Kullanım**:
    ```bash
    taaos-ai status
    taaos-ai install all
    taaos-ai shell
    ```

### 5. `taaos-linux` — Çekirdek Başlıkları, eBPF Profil Çıkarma ve Sysctl İnce Ayarı
Sistem programlama, çekirdek modülü derleme ve performans profillerini yönetir:
*   **Hedefler (`target`)**:
    *   `headers`: Linux çekirdek başlıkları (`linux-headers`), `dkms`, `build-essential`, `llvm`, `clang`
    *   `profiling`: `linux-perf`, `bpftrace`, `valgrind`, `strace`, `ltrace`, `gdb`
    *   `telemetry`: `inxi`, `lshw`, `sysstat` (`iostat`, `mpstat`, `pidstat`, `sar`)
    *   `tune`: Çekirdek `sysctl` optimizasyon profillerini uygular (`desktop`, `server`, `latency`)
    *   `all`: Tüm çekirdek ve sistem mühendisliği araçlarını kurar
*   **Örnek Kullanım**:
    ```bash
    taaos-linux status
    taaos-linux install profiling
    taaos-linux tune latency
    ```

---

## Sistem Yönetimi ve Bakım Komutları

| Komut | Açıklama |
| :--- | :--- |
| `taaos-doctor` | Kapsamlı sistem sağlık raporu üretir: işletim sistemi kimliği, çekirdek sürümü, CPU/RAM/Disk kullanımı, aktif servisler, ağ bağlantısı ve tüm `taaos-*` modüllerinin kurulum durumu. |
| `taaos-update` | Sistem genelinde APT güncellemelerini yapar, yarım kalmış paketleri onarır (`dpkg --configure -a`), kurulu `taaos-*` modüllerini ve TaaNOS ikili dosyasını günceller. |
| `taaos-clean` | APT önbelleğini temizler, yetim paketleri kaldırır (`autoremove`), eski günlükleri ve geçici önbellek dosyalarını siler. |
| `taaos-help` | Tüm TaaOS komutları ve kısayolları için hızlı başvuru kılavuzunu görüntüler. |
| `taaos-drivers` | PCI/USB donanımlarını tarar; ekran kartı, ağ ve firmware sürücülerinin kurulumuna yardımcı olur. |
| `taaos-harden` | Sistem güvenlik sıkılaştırma kurallarını (UFW güvenlik duvarı, sysctl ağ korumaları, SSH sıkılaştırması) uygular. |
| `taaos-rescue` | Önyükleyici (GRUB), `fstab`, `initramfs` ve paket veritabanı kurtarma işlemleri için acil onarım aracı. |
| `taaos-boot-analyze` | Açılış servislerini ve aktif OpenRC çalışma seviyelerini (runlevels) analiz eder. |
| `taaos-dll-handler` | Windows `.dll` dosyalarını Wine üzerinden kaydeder, siler, inceler veya çalıştırır (`taaos-dll-handler <dosya.dll> [register\|unregister\|info\|run]`). |
| `taaos-node-repl` | Etkileşimli Node.js REPL terminal konsolunu başlatır. |
| `taaos-create-persistent-usb` | Canlı USB belleği kalıcı depolama (persistence) bölümüyle biçimlendirir ve yapılandırır. |
| `taaos-setup-persistence` | Hedef disk bölümünde Live USB kalıcılık (`persistence.conf`) yapılandırmasını oluşturur. |

---

## TaaNOS — Yerel Doğal Dil Yapay Zeka Motoru

TaaNOS (`taanos` veya `ai`), TaaOS'un yerleşik terminal yapay zeka asistanı ve doğal dil komut motorudur:
*   **Çevrimdışı Anlık Eşleşme (0ms)**: Sık kullanılan sistem yönetimi istekleri (paket güncelleme, disk alanı kontrolü, açık portları listeleme, bellek durumu, servis yönetimi) LLM beklemeden 0ms içinde çevrimdışı olarak eşleştirilir.
*   **Yerel LLM Entegrasyonu (Ollama)**: Karmaşık sorular ve kod üretimi istekleri yerel Ollama hattına bağlanır (Ollama servisi kapalıysa otomatik başlatır) ve sistemde kurulu olan modeli dinamik olarak algılar.
*   **Etkileşimli TUI ve Tek Satır CLI**:
    *   Tam ekran etkileşimli arayüz için: `taanos`
    *   Doğrudan komut çevirisi için: `taanos "açık portları göster"` veya `ai "sistemi güncelle"`
    *   Model ve bağlantı yönetimi için: `taanos status` ve `taanos model`
*   **Güvenlik Korumaları**: İki kademeli güvenlik katmanı, yıkıcı komutları (`rm -rf /`, fork bomb, disk sıfırlama) engeller ve sistem değişikliği yapan komutlardan önce kullanıcı onayı alır.

---

## Servisler ve Çalışma Seviyesi (Runlevel) Tasarımı

TaaOS, çekirdek masaüstü servisleri ile ağır geliştirici servislerini birbirinden ayırır; böylece sistem saniyeler içinde açılır ve ağır servisler yalnızca ihtiyaç duyulduğunda başlatılır.

### Açılışta Aktif Çekirdek Servisler (OpenRC `default` Runlevel)
*   `dbus`: Sistem mesaj veri yolu
*   `elogind`: Masaüstü oturum, yetki ve güç yönetimi
*   `network-manager`: Kablolu ve kablosuz ağ yönetimi
*   `lightdm`: Grafiksel giriş ekranı yöneticisi
*   `plymouth`: Açılış ekranı yöneticisi
*   `chrony`: Hızlı NTP ağ saat eşitleme servisi (`makestep 1.0 -1`)
*   `zramswap`: Sıkıştırılmış RAM takas alanı (`zstd` sıkıştırma ile toplam RAM'in `%50`'si)
*   `earlyoom`: Ağır derleme veya yapay zeka yüklerinde sistemin donmasını önleyen erken bellek koruyucu
*   `ufw`: Güvenlik duvarı

### İsteğe Bağlı Servisler (Hızlı Açılış İçin Başlangıçta Kapalı)
Aşağıdaki ağır servisler açılışta otomatik başlamaz; istenildiğinde `sudo rc-service <servis> start` veya `sudo systemctl start <servis>` ile başlatılabilir:
*   `docker` ve `containerd` (Konteyner motoru)
*   `libvirtd` ve `virtlogd` (KVM/QEMU sanallaştırma servisi)
*   `cups` ve `cups-browsed` (Yazıcı servisi)
*   `bluetooth` (Bluetooth servisi — Hızlı Ayarlar'dan veya komuttan başlatılır)
*   `rasdaemon` (Sunucu anakartları için ECC bellek hata izleme servisi)
*   `fail2ban` ve `clamav-daemon` (Ek güvenlik servisleri)

---

## Önyüklü Temel Paketler ve Kabuk (Shell) Ortamı

*   **Modern Rust/C CLI Araçları**:
    *   `fastfetch` (Satır kaymasını önleyen `disableLineWrap` korumalı özel TaaOS ASCII logosu ve donanım özeti)
    *   `bat` / `batcat` (Sözdizimi renklendirmeli `cat` kısayolu)
    *   `eza` / `lsd` (İkon destekli `ls`, `ll`, `tree` kısayolları)
    *   `ripgrep` (`rg` hızlı metin arama)
    *   `fzf` (`Ctrl+R` geçmiş aramalı bulanık arama aracı)
    *   `zoxide` (Akıllı dizin geçiş aracı)
    *   `btop` ve `htop` (Etkileşimli sistem kaynak izleyicileri)
*   **Kabuklar ve Editörler**: Bash (TaaOS kısayolları ve güvenlik bariyerleri ile varsayılan), Zsh (`zsh-autosuggestions` ve `zsh-syntax-highlighting` eklentili), Neovim, Vim, Micro, Nano.
*   **Kabuk Güvenlik Bariyerleri (`/etc/profile.d/taaos-safety.sh`)**:
    *   Kritik kök dizinleri (`/`, `/etc`, `/usr`, `/boot`, `/home`, `/var`) hedef alan özyinelemeli `rm` komutlarını yakalar ve engeller.
    *   Fiziksel blok cihazlarını (`/dev/sd*`, `/dev/nvme*`, `/dev/vd*`) hedef alan `dd` yazma işlemlerinde açık onay ister.
    *   Kabuk seviyesinde fork bomb girişimlerini engeller.

---

## Derleme ve Kurulum

TaaOS, ana bilgisayarınızı kirletmemek için Docker tabanlı izole bir konteyner içinde derlenir.

### 1. Kurulabilir Canlı ISO Derleme (`TaaOS.iso`)
```bash
./build.sh
```
Derleme betiği aşağıdaki aşamaları otomatik olarak yürütür:
1.  `taaos-builder:torvalds` Docker imajını (Debian Trixie ortamı) oluşturur.
2.  Paket listelerini (`config/package-lists/*.list.chroot`), kancaları (`config/hooks/live/*.hook.chroot`), betikleri (`scripts/`) ve kök dosya sistemi katmanlarını (`config/includes.chroot/`) konteynere aktarır.
3.  `../TaaNOS/bin/` altında yerel TaaNOS derlemesi varsa doğrudan ISO içine enjekte eder.
4.  Özel ana hat Linux çekirdeğini (`compile_kernel.sh`) derler ve `.deb` paketlerine dönüştürür.
5.  `live-build` (`lb build`) ile Debian Trixie kök dosya sistemini kurar, tüm paketleri yükler, `00`–`99` arası tüm yapılandırma kancalarını (`98-systemd-free.hook.chroot` dahil) çalıştırır ve hem UEFI hem Legacy BIOS uyumlu hibrit `TaaOS.iso` dosyasını üretir.

### 2. WSL Terminal Sürümü Derleme (`TaaOS-WSL.tar.gz`)
```bash
./build_wsl.sh
```
Windows Subsystem for Linux (WSL2) için gereksiz masaüstü paketlerinden arındırılmış, TaaOS terminal ortamını, `fastfetch` kimliğini, Systemd-Free yapılandırmasını (`/etc/wsl.conf` içinde `systemd=false`), ilk açılış kullanıcı kurulum sihirbazını (`taaos-wsl-setup`) ve tüm `taaos-*` Modüler CRUD Geliştirici Yığınını içeren `TaaOS-WSL.tar.gz` arşivini üretir.
