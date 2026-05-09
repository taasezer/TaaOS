# TaaOS

TaaOS is a professional Linux distribution built on the **Debian 12 (Bookworm)** infrastructure, optimized specifically for **software engineers, data scientists, and DevOps experts**. The system comes pre-loaded with modern development tools, AI libraries, and automation services.

## Built-in Features and Software Packages

TaaOS offers the following tools and libraries ready to use after installation, without requiring additional configuration:

### Programming Languages and Installed Libraries

TaaOS comes with the following languages and libraries:

*   **Python (AI & Data Science)**
    *   **Version**: Python 3.11+
    *   **Artificial Intelligence (AI)**: `tensorflow-cpu`, `torch` (PyTorch CPU), `scikit-learn`, `xgboost`, `ollama`, `rich`
    *   **Data Science**: `numpy`, `pandas`, `scipy`, `matplotlib`, `seaborn`
    *   **Image Processing**: `opencv-python-headless`, `pillow`
    *   **Web & API**: `django`, `flask`, `fastapi`, `uvicorn`, `requests`, `httpx`
    *   **Tools**: `jupyter`, `jupyterlab`, `notebook`, `tqdm`, `click`, `pyyaml`, `python-dotenv`, `virtualenv`

*   **C / C++ (System Programming)**
    *   **Compilers**: GCC, G++, Clang, LLVM, MinGW-w64 (Cross-compile)
    *   **Build Systems**: CMake, Ninja, Make, Autoconf, Automake, Libtool, Pkg-config
    *   **Debug/Analysis**: GDB, Valgrind, Strace, Ltrace
    *   **Installed Libraries**: 
        *   `libboost-all-dev`: Boost C++ Libraries
        *   `libssl-dev`: OpenSSL Development Files
        *   `libcurl4-openssl-dev`: cURL Transfer Library
        *   `libjson-c-dev`: JSON-C Handler
        *   `libsqlite3-dev`: SQLite3 Database
        *   `libstdc++-12-dev`: GNU Standard C++ Library v3

*   **C# / .NET (Microsoft)**
    *   **SDK**: .NET 8 SDK (`dotnet-sdk-8.0`)
    *   **Runtime**: ASP.NET Core Runtime 8.0
    *   **Tools**: NuGet Package Manager

*   **JavaScript / Node.js**
    *   **Runtime**: Node.js v20.x (LTS)
    *   **Package Manager**: npm (Latest)
    *   **Global Tools**: n8n (Workflow Automation)

*   **Rust**
    *   **Core**: `rustc` (Compiler), `cargo` (Package Manager)
    *   **Source**: Debian stable repositories

*   **Other Languages**
    *   **Java**: OpenJDK (Default JDK/JRE)
    *   **Go (Golang)**: Go Programming Language Compiler
    *   **Perl**: Standard installation
    *   **Bash/Shell**: Modern Bash, scripting tools

### AI Assistant (Natural Engine)
*   **Natural Engine**: A local AI assistant using the installed `python` and `ollama` infrastructure.
*   **Usage**: Translates natural language requests into Bash commands by typing `natural "list files"` or `n "update system"` in the terminal.
*   **Auto-Sudo**: All commands are automatically executed with `sudo` privileges — no manual prefix needed.
*   **Code Save**: When Natural generates code, it automatically detects code blocks and offers to save them as files (15+ language extensions auto-detected).
*   **Safety Guardrails**: Two-tier protection — destructive commands (`rm -rf /`, fork bombs) are hard-blocked; potentially dangerous commands trigger a confirmation prompt.

### DevOps and Container Management
*   **Docker**: Docker Engine CE, Docker Buildx
*   **Orchestration**: Docker Compose (v2)
*   **Management Interfaces**: 
    *   Portainer CE (Web-based Docker management)
    *   Lazydocker (Terminal-based interface)
    *   Ctop (Container monitoring)
*   **Cloud Tools**: AWS CLI, Google Cloud SDK (optional add-on), Git, Git-LFS

### System Management and Automation
*   **Automation**: **n8n** workflow automation service (Pre-installed and runs as a service).
*   **System Panel**: **Cockpit** web-based management console (Storage, Network, Updates).
*   **Backup**: **Timeshift** system restore points (Snapshot).
*   **Virtualization**: KVM/QEMU, Libvirt, Virt-Manager (Virtual Machine Management).
*   **Network Analysis**: Wireshark, Nmap, Tcpdump, Htop, Btop, Iftop.
*   **Self-Healing**: `taaos-update` utility to automatically fix broken packages, apply OS core patches from GitHub, and verify AI Engine status.
*   **DLL Support**: `taaos-dll-handler` command to register, unregister, inspect, or run Windows .dll files via Wine. Double-click support in file manager.

### Desktop and Terminal
*   **Desktop Environment**: XFCE4 (Customized, lightweight, and fast).
*   **Welcome Screen**: Multilingual (Turkish/English) quick-start graphical guide on first boot.
*   **Terminal Experience**: Dracula-styled black terminal with pre-configured aliases (`ll`, `ports`, `update`) and customized Plane Tree (Çınar) Fastfetch system summary.
*   **Terminal Emulators**: XFCE4-Terminal (default), Tilix (advanced split-pane terminal), tmux, screen.
*   **Node.js REPL**: Dedicated Node.js interactive console launcher (`taaos-node-repl`).
*   **Git GUI**: Gitg (GTK visual branch/commit browser), Gitk (history viewer), Tig (terminal interface).
*   **Development Environment**: 
    *   **Visual Studio Code**: Pre-installed. (`vscode-extensions` command installs recommended extensions: Python, C#, Rust, Docker, Copilot, etc.)
    *   Vim, Nano, Micro editors.

### Security
*   **Safety Barriers**: System-wide protection against accidental destruction. `rm -rf /` and critical system directory deletions are blocked at the shell level.
*   **dd Protection**: Writing to block devices (`/dev/sd*`, `/dev/nvme*`) requires explicit confirmation.
*   **Post-Install Cleanup**: Calamares installer, desktop shortcut, and live user are automatically removed after installation.

## Build and Installation

TaaOS is built in a Docker-based isolated environment via the `build.sh` script. This method ensures a clean ISO creation without polluting your main system.

### Build Steps
1.  Open the terminal and navigate to the project directory.
2.  Run the `build.sh` file:
    ```bash
    ./build.sh
    ```
3.  Build Process (Automatic):
    *   **Cleanup**: Old containers and temporary files are cleaned.
    *   **Docker Environment**: `taaos-builder` image is created.
    *   **File Injection**: Package lists, libraries, and configuration files are copied into the container.
    *   **Kernel Build**: (Optional) Customized Linux kernel is compiled.
    *   **Live-Build**: Debian-based live system (squashfs) and ISO image are created with `lb build` command.
    *   **Output**: When finished, `TaaOS.iso` file is created in the directory.

### Post-Installation Access
*   **User**: Created during installation via Calamares installer.
*   **n8n Panel**: `http://localhost:5678`
*   **Portainer**: `http://localhost:9000`
*   **Cockpit**: `https://localhost:9090`

## Project Diagram
-----------------------------------------------------------------------------------------------------------------------------------------
<img width="2464" height="3016" alt="diagram" src="https://github.com/user-attachments/assets/957c2b28-673b-4b17-83a6-378d8de133da" />

-----------------------------------------------------------------------------------------------------------------------------------------

## Screenshots
---
### First Screen
<img width="808" height="603" alt="Ekran görüntüsü 2026-03-30 013647" src="https://github.com/user-attachments/assets/19c1db20-c304-4ff2-a33b-21b8df891d21" />

---
### Terminal

<img width="800" height="403" alt="image" src="https://github.com/user-attachments/assets/97d29ab5-37d7-4421-8a1c-4d99428c6d72" />

---

# TaaOS (Türkçe)

TaaOS, Debian 12 (Bookworm) altyapısı üzerine inşa edilmiş, yazılım mühendisleri, veri bilimciler ve DevOps uzmanları için özel olarak optimize edilmiş profesyonel bir Linux dağıtımıdır. Sistem, modern geliştirme araçları, yapay zeka kütüphaneleri ve otomasyon servisleri ile yüklü olarak gelir.

## Dahili Özellikler ve Yazılım Paketleri

TaaOS, kurulumdan sonra ek yapılandırma gerektirmeden aşağıdaki araçları ve kütüphaneleri sunar:

### Programlama Dilleri ve Yüklü Kütüphaneler

TaaOS, aşağıdaki diller ve kütüphanelerle birlikte gelir:

*   **Python (AI ve Veri Bilimi)**
    *   **Versiyon**: Python 3.11+
    *   **Yapay Zeka (AI)**: `tensorflow-cpu`, `torch` (PyTorch CPU), `scikit-learn`, `xgboost`, `ollama`, `rich`
    *   **Veri Bilimi**: `numpy`, `pandas`, `scipy`, `matplotlib`, `seaborn`
    *   **Görüntü İşleme**: `opencv-python-headless`, `pillow`
    *   **Web & API**: `django`, `flask`, `fastapi`, `uvicorn`, `requests`, `httpx`
    *   **Araçlar**: `jupyter`, `jupyterlab`, `notebook`, `tqdm`, `click`, `pyyaml`, `python-dotenv`, `virtualenv`

*   **C / C++ (Sistem Programlama)**
    *   **Derleyiciler**: GCC, G++, Clang, LLVM, MinGW-w64 (Cross-compile)
    *   **Build Sistemleri**: CMake, Ninja, Make, Autoconf, Automake, Libtool, Pkg-config
    *   **Debug/Analiz**: GDB, Valgrind, Strace, Ltrace
    *   **Kurulu Kütüphaneler**: 
        *   `libboost-all-dev`: Boost C++ Kütüphaneleri
        *   `libssl-dev`: OpenSSL Geliştirme Dosyaları
        *   `libcurl4-openssl-dev`: cURL Transfer Kütüphanesi
        *   `libjson-c-dev`: JSON-C İşleyici
        *   `libsqlite3-dev`: SQLite3 Veritabanı
        *   `libstdc++-12-dev`: GNU Standart C++ Kütüphanesi v3

*   **C# / .NET (Microsoft)**
    *   **SDK**: .NET 8 SDK (`dotnet-sdk-8.0`)
    *   **Runtime**: ASP.NET Core Runtime 8.0
    *   **Araçlar**: NuGet Paket Yöneticisi

*   **JavaScript / Node.js**
    *   **Runtime**: Node.js v20.x (LTS)
    *   **Paket Yöneticisi**: npm (Latest)
    *   **Global Araçlar**: n8n (Workflow Automation)

*   **Rust**
    *   **Core**: `rustc` (Derleyici), `cargo` (Paket Yöneticisi)
    *   **Kaynak**: Debian stable depoları

*   **Diğer Diller**
    *   **Java**: OpenJDK (Default JDK/JRE)
    *   **Go (Golang)**: Go Programming Language Compiler
    *   **Perl**: Standart kurulum
    *   **Bash/Shell**: Modern Bash, betik araçları

### Yapay Zeka Asistanı (Natural Engine)
*   **Natural Engine**: Sistemde yüklü olan `python` ve `ollama` altyapısını kullanan yerel yapay zeka asistanı.
*   **Kullanım**: Terminalde `natural "dosyaları listele"` veya `n "sistemi güncelle"` yazarak doğal dildeki istekleri Bash komutlarına çevirir.
*   **Otomatik Sudo**: Tüm komutlar otomatik olarak `sudo` ile çalıştırılır — manuel prefix gerekmez.
*   **Kod Kaydetme**: Natural kod ürettiğinde otomatik olarak kod bloklarını algılar ve dosya olarak kaydetmeyi teklif eder (15+ dil uzantısı otomatik algılanır).
*   **Güvenlik Korumaları**: İki kademeli koruma — yıkıcı komutlar (`rm -rf /`, fork bomb) tamamen engellenir; potansiyel tehlikeli komutlar onay ister.

### DevOps ve Konteyner Yönetimi
*   **Docker**: Docker Engine CE, Docker Buildx
*   **Orkestrasyon**: Docker Compose (v2)
*   **Yönetim Arayüzleri**: 
    *   Portainer CE (Web tabanlı Docker yönetimi)
    *   Lazydocker (Terminal tabanlı arayüz)
    *   Ctop (Konteyner izleme)
*   **Bulut Araçları**: AWS CLI, Google Cloud SDK (opsiyonel eklenebilir), Git, Git-LFS

### Sistem Yönetimi ve Otomasyon
*   **Otomasyon**: **n8n** iş akışı otomasyon servisi (Önyüklü ve servis olarak çalışır).
*   **Sistem Paneli**: **Cockpit** web tabanlı yönetim konsolu (Depolama, Ağ, Güncellemeler).
*   **Yedekleme**: **Timeshift** ile sistem geri yükleme noktaları (Snapshot).
*   **Sanallaştırma**: KVM/QEMU, Libvirt, Virt-Manager (Sanal Makine Yönetimi).
*   **Ağ Analizi**: Wireshark, Nmap, Tcpdump, Htop, Btop, Iftop.
*   **Otomatik Onarım**: `taaos-update` komutu ile kırık paket, sistem güncellemesi, GitHub bağımlı çekirdek yamaları ve Natural Engine sağlık kontrolünü tek tıkla yapma imkanı.
*   **DLL Desteği**: `taaos-dll-handler` komutu ile Windows .dll dosyalarını Wine üzerinden kaydetme, silme, inceleme veya çalıştırma. Dosya yöneticisinde çift tıklama desteği.

### Masaüstü ve Terminal
*   **Masaüstü Ortamı**: XFCE4 (Özelleştirilmiş, hafif ve hızlı).
*   **Karşılama Ekranı**: İlk kurulumda açılan çok dilli (Türkçe/İngilizce) grafiksel rehber arayüzü.
*   **Terminal Deneyimi**: Dracula temalı siyah arka plan, hazır komut kısayolları (`ll`, `ports`, `update`) ve özel TaaOS Çınar Ağacı (Fastfetch) sistem özeti.
*   **Terminal Emülatörleri**: XFCE4-Terminal (varsayılan), Tilix (gelişmiş bölünmüş ekran), tmux, screen.
*   **Node.js REPL**: Özel Node.js etkileşimli konsol başlatıcısı (`taaos-node-repl`).
*   **Git GUI**: Gitg (GTK görsel dal/commit tarayıcı), Gitk (geçmiş görüntüleyici), Tig (terminal arayüzü).
*   **Geliştirme Ortamı**: 
    *   **Visual Studio Code**: Önyüklü gelir. (`vscode-extensions` komutu ile önerilen eklentileri kurar: Python, C#, Rust, Docker, Copilot vb.)
    *   Vim, Nano, Micro editörleri.

### Güvenlik
*   **Güvenlik Bariyerleri**: Kazara yıkımı önleyen sistem genelinde koruma. `rm -rf /` ve kritik sistem dizini silme işlemleri kabuk seviyesinde engellenir.
*   **dd Koruması**: Blok cihazlarına (`/dev/sd*`, `/dev/nvme*`) yazma işlemi açık onay gerektirir.
*   **Kurulum Sonrası Temizlik**: Calamares yükleyici, masaüstü kısayolu ve live kullanıcı kurulumdan sonra otomatik olarak kaldırılır.

## Derleme ve Kurulum

TaaOS, `build.sh` betiği üzerinden Docker tabanlı izole bir ortamda derlenir. Bu yöntem, ana sisteminizi kirletmeden temiz bir ISO oluşturulmasını sağlar.

### Derleme Adımları
1.  Terminali açın ve proje dizinine gidin.
2.  `build.sh` dosyasını çalıştırın:
    ```bash
    ./build.sh
    ```
3.  Derleme Süreci (Otomatik):
    *   **Temizlik**: Eski konteyner ve geçici dosyalar temizlenir.
    *   **Docker Ortamı**: `taaos-builder` imajı oluşturulur.
    *   **Dosya Enjeksiyonu**: Paket listeleri, kütüphaneler ve yapılandırma dosyaları konteyner içine kopyalanır.
    *   **Kernel Derleme**: (Opsiyonel) Özelleştirilmiş Linux çekirdeği derlenir.
    *   **Live-Build**: `lb build` komutu ile Debian tabanlı canlı sistem (squashfs) ve ISO imajı oluşturulur.
    *   **Çıktı**: İşlem bittiğinde dizinde `TaaOS.iso` dosyası oluşur.

### Kurulum Sonrası Erişim
*   **Kullanıcı**: Calamares yükleyici aracılığıyla kurulum sırasında oluşturulur.
*   **n8n Paneli**: `http://localhost:5678`
*   **Portainer**: `http://localhost:9000`
*   **Cockpit**: `https://localhost:9090`
