# TaaOS GitHub-Based Update & Testing System
**Projeyi GitHub merkezli otomatik güncelleme sistemi ile yapılandırma**

---

## 📁 PROJE YAPISINI YENİDEN DÜZENLEME

### Şu anki yapı → Olması gereken yapı

```
TaaOS/
├── .github/
│   ├── workflows/
│   │   ├── build-iso.yml           # ISO otomatik build
│   │   ├── test-suite.yml          # Kapsamlı testler
│   │   └── release.yml             # Release otomasyonu
│   └── ISSUE_TEMPLATE/
│
├── releases/                        # ⭐ YENİ
│   ├── version.json                # Mevcut versiyon bilgisi
│   ├── changelog.json              # Değişiklik günlüğü
│   └── updates/                    # Kısmi güncelleme paketleri
│       ├── v1.0.1-patch.tar.gz
│       └── v1.0.2-patch.tar.gz
│
├── scripts/
│   ├── system/                     # ⭐ YENİ - Runtime scripts
│   │   ├── taaos-update-client.sh  # Client-side update script
│   │   ├── taaos-self-heal.sh      # Self-healing system
│   │   └── taaos-health-check.sh   # Boot-time health check
│   │
│   └── build/                      # Build-time scripts
│       ├── build.sh
│       ├── compile_kernel.sh
│       └── ...
│
├── tests/                          # ⭐ YENİ - Comprehensive testing
│   ├── integration/
│   │   ├── boot-test.sh
│   │   ├── package-test.sh
│   │   └── service-test.sh
│   ├── unit/
│   └── run-all-tests.sh
│
├── config/
│   ├── includes.chroot/
│   │   ├── usr/local/bin/          # Runtime tools
│   │   ├── etc/systemd/system/     # Services
│   │   └── etc/taaos/              # ⭐ YENİ - TaaOS configs
│   │       ├── update.conf
│   │       └── repo.conf
│   └── ...
│
└── docs/
    ├── ARCHITECTURE.md
    ├── UPDATE_SYSTEM.md
    └── TESTING.md
```

---

## 🔄 BÖLÜM 1: GITHUB-BASED UPDATE SYSTEM

### 1.1 GitHub Repository Yapısı

**releases/ dizini** (GitHub'da tutulacak):

```bash
# releases/version.json
{
  "current_version": "1.0.0",
  "release_date": "2026-01-29",
  "download_url": "https://github.com/taasezer/TaaOS/releases/download/v1.0.0/TaaOS-v1.0.0.iso",
  "checksum": {
    "sha256": "abc123...",
    "md5": "def456..."
  },
  "min_supported_version": "0.9.0",
  "update_available": true,
  "update_type": "minor",
  "update_size_mb": 250,
  "breaking_changes": false
}
```

```bash
# releases/changelog.json
{
  "versions": [
    {
      "version": "1.0.0",
      "date": "2026-01-29",
      "type": "major",
      "changes": {
        "added": [
          "Natural Engine AI assistant",
          "Auto-update system",
          "Self-healing capabilities"
        ],
        "fixed": [
          "Boot time optimization",
          "Docker networking issues"
        ],
        "security": [
          "SSH hardening",
          "Firewall default rules"
        ]
      },
      "download_url": "https://github.com/taasezer/TaaOS/releases/download/v1.0.0/TaaOS-v1.0.0.iso",
      "patch_url": "https://github.com/taasezer/TaaOS/releases/download/v1.0.0/update-0.9.0-to-1.0.0.tar.gz"
    }
  ]
}
```

### 1.2 Client-Side Update Script

**scripts/system/taaos-update-client.sh** (ISO'ya gömülecek):

```bash
#!/bin/bash
# TaaOS Auto-Update Client
# Bu script her boot'ta çalışır ve güncellemeleri kontrol eder

set -euo pipefail

# Konfigürasyon
REPO_URL="https://raw.githubusercontent.com/taasezer/TaaOS/main/releases"
VERSION_FILE="/etc/taaos/version"
UPDATE_CACHE="/var/cache/taaos/updates"
LOG_FILE="/var/log/taaos/update.log"

# Renkli output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

# Mevcut versiyonu al
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"
    fi
}

# GitHub'dan güncel versiyon bilgisini çek
fetch_latest_version() {
    local max_retries=3
    local retry_delay=5
    
    for i in $(seq 1 $max_retries); do
        if curl -fsSL --max-time 10 "$REPO_URL/version.json" -o /tmp/taaos-version.json 2>/dev/null; then
            return 0
        fi
        warn "GitHub'a bağlanılamadı, tekrar deneniyor... ($i/$max_retries)"
        sleep $retry_delay
    done
    
    error "GitHub'dan versiyon bilgisi alınamadı"
    return 1
}

# Versiyon karşılaştırma (semantic versioning)
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Güncelleme kontrolü
check_for_updates() {
    info "Güncelleme kontrolü yapılıyor..."
    
    local current_version=$(get_current_version)
    info "Mevcut versiyon: v$current_version"
    
    # GitHub'dan versiyon bilgisi çek
    if ! fetch_latest_version; then
        warn "Güncellemeler kontrol edilemedi (internet bağlantısı yok)"
        return 1
    fi
    
    # JSON parse et
    local latest_version=$(jq -r '.current_version' /tmp/taaos-version.json)
    local update_available=$(jq -r '.update_available' /tmp/taaos-version.json)
    local update_type=$(jq -r '.update_type' /tmp/taaos-version.json)
    local breaking_changes=$(jq -r '.breaking_changes' /tmp/taaos-version.json)
    
    info "Sunucu versiyonu: v$latest_version"
    
    # Versiyon karşılaştır
    if version_gt "$latest_version" "$current_version"; then
        success "🎉 Yeni güncelleme mevcut: v$latest_version"
        echo ""
        
        # Changelog göster
        show_changelog "$latest_version"
        
        # Güncelleme tipi uyarısı
        if [ "$breaking_changes" = "true" ]; then
            warn "⚠️  Bu güncelleme breaking changes içeriyor!"
            warn "⚠️  Devam etmeden önce verilerinizi yedekleyin!"
        fi
        
        # Kullanıcıya sor
        if [ "${AUTO_UPDATE:-false}" = "true" ]; then
            info "Otomatik güncelleme aktif, 10 saniye içinde başlayacak..."
            sleep 10
            perform_update "$latest_version"
        else
            ask_user_to_update "$latest_version"
        fi
    else
        success "✅ Sistem güncel (v$current_version)"
    fi
}

# Changelog göster
show_changelog() {
    local version=$1
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  DEĞIŞIKLIKLER (v$version)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    curl -fsSL "$REPO_URL/changelog.json" | jq -r \
        --arg ver "$version" \
        '.versions[] | select(.version == $ver) | 
         "
\(.date)

\(.changes.added | if length > 0 then "Eklenenler:\n" + (map("  ✓ " + .) | join("\n")) else "" end)

\(.changes.fixed | if length > 0 then "Düzeltilenler:\n" + (map("  🔧 " + .) | join("\n")) else "" end)

\(.changes.security | if length > 0 then "Güvenlik:\n" + (map("  🔒 " + .) | join("\n")) else "" end)
"'
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Kullanıcıya güncelleme için sor
ask_user_to_update() {
    local version=$1
    
    echo ""
    read -p "Güncellemek istiyor musunuz? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        perform_update "$version"
    else
        info "Güncelleme atlandı. Daha sonra 'sudo taaos-update now' komutu ile güncelleyebilirsiniz."
        
        # Hatırlatma ayarla
        echo "$version" > /var/lib/taaos/pending_update
    fi
}

# Güncelleme işlemini gerçekleştir
perform_update() {
    local target_version=$1
    
    info "🚀 Güncelleme başlatılıyor: v$target_version"
    
    # 1. Pre-update snapshot (Timeshift)
    info "📸 Sistem snapshot'ı alınıyor..."
    if command -v timeshift &> /dev/null; then
        timeshift --create --comments "Pre-update v$target_version" --scripted
    else
        warn "Timeshift bulunamadı, snapshot alınamıyor!"
    fi
    
    # 2. Güncelleme paketini indir
    info "📦 Güncelleme paketi indiriliyor..."
    
    local current_version=$(get_current_version)
    local patch_url=$(curl -fsSL "$REPO_URL/changelog.json" | \
        jq -r --arg ver "$target_version" \
        '.versions[] | select(.version == $ver) | .patch_url')
    
    mkdir -p "$UPDATE_CACHE"
    
    if ! wget -q --show-progress "$patch_url" -O "$UPDATE_CACHE/update.tar.gz"; then
        error "Güncelleme paketi indirilemedi!"
        return 1
    fi
    
    # 3. Checksum doğrula
    info "🔍 Güncelleme paketi doğrulanıyor..."
    
    local expected_checksum=$(jq -r '.checksum.sha256' /tmp/taaos-version.json)
    local actual_checksum=$(sha256sum "$UPDATE_CACHE/update.tar.gz" | awk '{print $1}')
    
    if [ "$expected_checksum" != "$actual_checksum" ]; then
        error "Checksum uyuşmazlığı! Güncelleme güvenli değil."
        rm -f "$UPDATE_CACHE/update.tar.gz"
        return 1
    fi
    
    success "✅ Güncelleme paketi doğrulandı"
    
    # 4. Güncellemeyi uygula
    info "⚙️  Güncelleme uygulanıyor..."
    
    cd "$UPDATE_CACHE"
    tar -xzf update.tar.gz
    
    # Update script çalıştır (her güncellemede özel script olabilir)
    if [ -f "$UPDATE_CACHE/update.sh" ]; then
        chmod +x "$UPDATE_CACHE/update.sh"
        bash "$UPDATE_CACHE/update.sh" || {
            error "Güncelleme scripti başarısız oldu!"
            rollback_update
            return 1
        }
    fi
    
    # 5. Sistem paketlerini güncelle
    info "📦 Sistem paketleri güncelleniyor..."
    apt-get update
    apt-get upgrade -y
    
    # 6. TaaOS özel bileşenlerini güncelle
    info "🔧 TaaOS bileşenleri güncelleniyor..."
    
    # Scripts güncelle
    if [ -d "$UPDATE_CACHE/scripts" ]; then
        rsync -av "$UPDATE_CACHE/scripts/" /usr/local/bin/
        chmod +x /usr/local/bin/taaos-*
    fi
    
    # Configs güncelle
    if [ -d "$UPDATE_CACHE/configs" ]; then
        rsync -av "$UPDATE_CACHE/configs/" /etc/taaos/
    fi
    
    # Services güncelle
    if [ -d "$UPDATE_CACHE/services" ]; then
        rsync -av "$UPDATE_CACHE/services/" /etc/systemd/system/
        systemctl daemon-reload
    fi
    
    # 7. Versiyon dosyasını güncelle
    echo "$target_version" > "$VERSION_FILE"
    
    # 8. Temizlik
    rm -rf "$UPDATE_CACHE"/*
    
    success "✅ Güncelleme başarıyla tamamlandı!"
    success "🎉 TaaOS v$target_version kuruldu!"
    
    # 9. Reboot gerekiyor mu?
    if [ -f /var/run/reboot-required ]; then
        warn "⚠️  Güncellemelerin tam etkili olması için yeniden başlatma gerekiyor"
        
        read -p "Şimdi yeniden başlatmak istiyor musunuz? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl reboot
        fi
    fi
}

# Rollback (güncelleme başarısız olursa)
rollback_update() {
    error "⚠️  Güncelleme başarısız, geri alınıyor..."
    
    if command -v timeshift &> /dev/null; then
        local latest_snapshot=$(timeshift --list | grep "Pre-update" | head -1 | awk '{print $3}')
        
        if [ -n "$latest_snapshot" ]; then
            warn "Son snapshot'a geri dönülüyor: $latest_snapshot"
            timeshift --restore --snapshot "$latest_snapshot" --scripted
            success "✅ Sistem önceki haline döndürüldü"
        fi
    else
        error "Timeshift bulunamadı, manuel geri alma gerekiyor!"
    fi
}

# Ana fonksiyon
main() {
    # Root kontrolü
    if [ "$EUID" -ne 0 ]; then
        error "Bu script root olarak çalıştırılmalı"
        exit 1
    fi
    
    # Log dizini oluştur
    mkdir -p "$(dirname $LOG_FILE)"
    mkdir -p "$(dirname $VERSION_FILE)"
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TaaOS Update Client v1.0"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    case "${1:-check}" in
        check)
            check_for_updates
            ;;
        now)
            # Doğrudan güncelle
            if fetch_latest_version; then
                local latest=$(jq -r '.current_version' /tmp/taaos-version.json)
                perform_update "$latest"
            fi
            ;;
        auto-enable)
            # Otomatik güncellemeyi aktif et
            sed -i 's/AUTO_UPDATE=false/AUTO_UPDATE=true/' /etc/taaos/update.conf
            success "Otomatik güncellemeler aktif edildi"
            ;;
        auto-disable)
            sed -i 's/AUTO_UPDATE=true/AUTO_UPDATE=false/' /etc/taaos/update.conf
            success "Otomatik güncellemeler devre dışı bırakıldı"
            ;;
        rollback)
            rollback_update
            ;;
        *)
            echo "Kullanım: $0 {check|now|auto-enable|auto-disable|rollback}"
            exit 1
            ;;
    esac
}

main "$@"
```

### 1.3 Boot-time Update Service

**config/includes.chroot/etc/systemd/system/taaos-update-check.service**:

```ini
[Unit]
Description=TaaOS Update Checker
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/taaos-update-client.sh check
StandardOutput=journal
StandardError=journal
TimeoutStartSec=300

# Sadece internet varsa çalıştır
ExecCondition=/bin/bash -c 'ping -c 1 -W 5 8.8.8.8 || exit 1'

[Install]
WantedBy=multi-user.target
```

**config/includes.chroot/etc/systemd/system/taaos-update-check.timer**:

```ini
[Unit]
Description=Check for TaaOS updates on boot and daily
After=network-online.target

[Timer]
# Boot'tan 2 dakika sonra çalıştır
OnBootSec=2min

# Sonrasında günlük kontrol
OnUnitActiveSec=1d

Persistent=true

[Install]
WantedBy=timers.target
```

**Kurulum (build sırasında):**

```bash
# config/hooks/live/9999-enable-update-service.hook.chroot
#!/bin/bash

systemctl enable taaos-update-check.timer
systemctl enable taaos-update-check.service

# Default config
cat > /etc/taaos/update.conf << 'EOF'
# TaaOS Update Configuration
AUTO_UPDATE=false          # Otomatik güncellemeleri aktif et/kapat
CHECK_ON_BOOT=true         # Boot'ta kontrol et
CHECK_INTERVAL=daily       # daily, weekly, monthly
NOTIFY_USER=true           # Kullanıcıya bildirim göster
REQUIRE_CONFIRMATION=true  # Güncellemeden önce onay iste
EOF
```

---

## 🧪 BÖLÜM 2: KAPSAMLI TEST SİSTEMİ

### 2.1 Test Yapısı

```
tests/
├── run-all-tests.sh          # Master test runner
├── integration/
│   ├── 01-boot-test.sh       # ISO boot testi
│   ├── 02-package-test.sh    # Paket integrity
│   ├── 03-service-test.sh    # Servis health check
│   ├── 04-network-test.sh    # Network connectivity
│   ├── 05-update-test.sh     # Update system testi
│   └── 06-recovery-test.sh   # Self-healing testi
├── unit/
│   ├── test-natural-engine.sh
│   ├── test-taaos-pkg.sh
│   └── test-config-scripts.sh
└── helpers/
    ├── qemu-helper.sh        # QEMU wrapper fonksiyonları
    └── test-utils.sh         # Utility fonksiyonlar
```

### 2.2 Master Test Runner

**tests/run-all-tests.sh**:

```bash
#!/bin/bash
# TaaOS Comprehensive Test Suite
# Her şeyi test eder: Build → Boot → Services → Update → Recovery

set -euo pipefail

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test sonuçları
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test log
TEST_LOG="test-results-$(date +%Y%m%d_%H%M%S).log"
mkdir -p test-results

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "test-results/$TEST_LOG"
}

test_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  TEST: $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

run_test() {
    local test_name=$1
    local test_script=$2
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    test_header "$test_name"
    
    if [ ! -f "$test_script" ]; then
        echo -e "${YELLOW}⊘ SKIPPED${NC} - Test script bulunamadı: $test_script"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return
    fi
    
    chmod +x "$test_script"
    
    if bash "$test_script" 2>&1 | tee -a "test-results/$TEST_LOG"; then
        echo -e "${GREEN}✓ PASSED${NC} - $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAILED${NC} - $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        # Kritik testlerde dur
        if [[ "$test_name" =~ "Boot Test" ]] || [[ "$test_name" =~ "Build" ]]; then
            echo -e "${RED}Kritik test başarısız, devam edilemiyor!${NC}"
            show_summary
            exit 1
        fi
    fi
}

show_summary() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  TEST SONUÇLARI${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Toplam Test:    $TOTAL_TESTS"
    echo -e "${GREEN}✓ Başarılı:     $PASSED_TESTS${NC}"
    echo -e "${RED}✗ Başarısız:    $FAILED_TESTS${NC}"
    echo -e "${YELLOW}⊘ Atlandı:      $SKIPPED_TESTS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "Başarı Oranı: ${success_rate}%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}🎉 Tüm testler başarılı! ISO production-ready.${NC}\n"
        return 0
    else
        echo -e "\n${RED}⚠️  Bazı testler başarısız! Lütfen logları kontrol edin.${NC}\n"
        return 1
    fi
}

# Test ISO var mı kontrol et
check_iso() {
    if [ ! -f "TaaOS.iso" ]; then
        echo -e "${RED}✗ TaaOS.iso bulunamadı!${NC}"
        echo "Önce ISO build edin: ./build.sh"
        exit 1
    fi
    
    echo -e "${GREEN}✓ ISO bulundu: $(ls -lh TaaOS.iso | awk '{print $5}')${NC}"
}

# Ana test akışı
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║             TaaOS Comprehensive Test Suite                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    log "Test suite başlatıldı"
    log "ISO: $(pwd)/TaaOS.iso"
    
    # ISO kontrolü
    check_iso
    
    # Integration Tests
    echo -e "\n${YELLOW}═══ INTEGRATION TESTS ═══${NC}\n"
    
    run_test "ISO Bootability Test" "tests/integration/01-boot-test.sh"
    run_test "Package Integrity Test" "tests/integration/02-package-test.sh"
    run_test "Service Health Check" "tests/integration/03-service-test.sh"
    run_test "Network Connectivity" "tests/integration/04-network-test.sh"
    run_test "Update System Test" "tests/integration/05-update-test.sh"
    run_test "Self-Healing Test" "tests/integration/06-recovery-test.sh"
    
    # Unit Tests
    echo -e "\n${YELLOW}═══ UNIT TESTS ═══${NC}\n"
    
    run_test "Natural Engine Test" "tests/unit/test-natural-engine.sh"
    run_test "Package Manager Test" "tests/unit/test-taaos-pkg.sh"
    run_test "Config Scripts Test" "tests/unit/test-config-scripts.sh"
    
    # Sonuç raporu
    show_summary
    
    # HTML rapor oluştur (opsiyonel)
    generate_html_report
}

generate_html_report() {
    local report_file="test-results/report-$(date +%Y%m%d_%H%M%S).html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>TaaOS Test Report</title>
    <style>
        body { font-family: monospace; background: #0a0e27; color: #e0e0e0; padding: 20px; }
        .pass { color: #00ff88; }
        .fail { color: #ff0055; }
        .skip { color: #ffaa00; }
        pre { background: #1a1f3a; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>TaaOS Test Report</h1>
    <p>Generated: $(date)</p>
    <p>Total: $TOTAL_TESTS | <span class="pass">Passed: $PASSED_TESTS</span> | <span class="fail">Failed: $FAILED_TESTS</span> | <span class="skip">Skipped: $SKIPPED_TESTS</span></p>
    <pre>
$(cat "test-results/$TEST_LOG")
    </pre>
</body>
</html>
EOF
    
    echo -e "\n${GREEN}📊 HTML rapor oluşturuldu: $report_file${NC}"
}

main "$@"
```

### 2.3 Boot Test (En Kritik)

**tests/integration/01-boot-test.sh**:

```bash
#!/bin/bash
# ISO boot testi - QEMU'da gerçek boot simülasyonu

set -euo pipefail

source tests/helpers/qemu-helper.sh

ISO_FILE="TaaOS.iso"
TIMEOUT=180  # 3 dakika
MEMORY="4096"
CPU_CORES="2"

echo "🚀 ISO Boot Test başlatılıyor..."
echo "   ISO: $ISO_FILE"
echo "   Memory: ${MEMORY}MB"
echo "   Timeout: ${TIMEOUT}s"

# Geçici dizin
TEST_DIR=$(mktemp -d)
trap "cleanup_test $TEST_DIR" EXIT

# QEMU ile boot et
boot_iso_qemu() {
    local log_file="$TEST_DIR/qemu-boot.log"
    
    timeout $TIMEOUT qemu-system-x86_64 \
        -m $MEMORY \
        -smp $CPU_CORES \
        -cdrom "$ISO_FILE" \
        -boot d \
        -nographic \
        -serial file:"$log_file" \
        -monitor none \
        -display none \
        &
    
    local qemu_pid=$!
    
    echo "⏳ QEMU başlatıldı (PID: $qemu_pid), boot bekleniyor..."
    
    # Boot tamamlanana kadar bekle
    local elapsed=0
    while [ $elapsed -lt $TIMEOUT ]; do
        if grep -q "login:" "$log_file" 2>/dev/null; then
            echo "✅ Login promptu tespit edildi!"
            kill $qemu_pid 2>/dev/null || true
            return 0
        fi
        
        if grep -qi "kernel panic\|error\|failed to boot" "$log_file" 2>/dev/null; then
            echo "❌ Boot hatası tespit edildi!"
            cat "$log_file"
            kill $qemu_pid 2>/dev/null || true
            return 1
        fi
        
        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done
    
    echo ""
    echo "❌ Timeout! Boot ${TIMEOUT} saniyede tamamlanamadı."
    kill $qemu_pid 2>/dev/null || true
    return 1
}

# Test et
if boot_iso_qemu; then
    echo "✅ Boot test BAŞARILI"
    exit 0
else
    echo "❌ Boot test BAŞARISIZ"
    exit 1
fi
```

### 2.4 Update System Test

**tests/integration/05-update-test.sh**:

```bash
#!/bin/bash
# Update sistem testi - Gerçek güncelleme simülasyonu

set -euo pipefail

echo "🔄 Update System Test başlatılıyor..."

# Mock GitHub server oluştur
setup_mock_github() {
    local port=8080
    local mock_dir=$(mktemp -d)
    
    # Mock version.json
    cat > "$mock_dir/version.json" << 'EOF'
{
  "current_version": "1.0.1",
  "release_date": "2026-01-30",
  "download_url": "http://localhost:8080/update.tar.gz",
  "checksum": {
    "sha256": "test123"
  },
  "update_available": true,
  "update_type": "minor",
  "breaking_changes": false
}
EOF
    
    # Mock update paketi
    mkdir -p "$mock_dir/update-contents"
    echo "#!/bin/bash" > "$mock_dir/update-contents/update.sh"
    echo "echo 'Test update script'" >> "$mock_dir/update-contents/update.sh"
    
    cd "$mock_dir/update-contents"
    tar -czf "../update.tar.gz" *
    cd -
    
    # Basit HTTP server başlat
    (cd "$mock_dir" && python3 -m http.server $port > /dev/null 2>&1) &
    local server_pid=$!
    
    echo "$mock_dir $server_pid"
}

# Test update client
test_update_client() {
    # Mock server başlat
    local mock_info=$(setup_mock_github)
    local mock_dir=$(echo $mock_info | awk '{print $1}')
    local server_pid=$(echo $mock_info | awk '{print $2}')
    
    trap "kill $server_pid 2>/dev/null; rm -rf $mock_dir" EXIT
    
    sleep 2  # Server'ın başlamasını bekle
    
    # Update client'ı test et (dry-run mode)
    export REPO_URL="http://localhost:8080"
    export DRY_RUN=true
    
    if bash scripts/system/taaos-update-client.sh check; then
        echo "✅ Update check başarılı"
    else
        echo "❌ Update check başarısız"
        return 1
    fi
    
    # Cleanup
    kill $server_pid 2>/dev/null
    rm -rf "$mock_dir"
}

if test_update_client; then
    echo "✅ Update system test BAŞARILI"
    exit 0
else
    echo "❌ Update system test BAŞARISIZ"
    exit 1
fi
```

---

## 🔧 BÖLÜM 3: GITHUB ACTIONS CI/CD

### 3.1 Automatic ISO Build & Test

**.github/workflows/build-and-test.yml**:

```yaml
name: Build and Test TaaOS

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:  # Manuel trigger

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Free disk space
        run: |
          sudo rm -rf /usr/share/dotnet
          sudo rm -rf /opt/ghc
          sudo rm -rf /usr/local/share/boost
          sudo apt-get clean
          df -h
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            qemu-system-x86 \
            qemu-utils \
            ovmf \
            jq \
            python3
      
      - name: Build ISO
        run: |
          chmod +x build.sh
          ./build.sh
      
      - name: Run comprehensive tests
        run: |
          chmod +x tests/run-all-tests.sh
          sudo ./tests/run-all-tests.sh
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
      
      - name: Upload ISO (if tests pass)
        if: success()
        uses: actions/upload-artifact@v3
        with:
          name: TaaOS-${{ github.sha }}
          path: TaaOS*.iso
          retention-days: 30
      
      - name: Comment PR with results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const results = fs.readFileSync('test-results/test-results-*.log', 'utf8');
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Test Results\n\`\`\`\n${results}\n\`\`\``
            });
  
  security-scan:
    runs-on: ubuntu-latest
    needs: build
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

### 3.2 Automatic Release

**.github/workflows/release.yml**:

```yaml
name: Create Release

on:
  push:
    tags:
      - 'v*'  # v1.0.0, v1.0.1, vb.

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Build ISO
        run: |
          chmod +x build.sh
          ./build.sh
      
      - name: Calculate checksums
        run: |
          sha256sum TaaOS*.iso > TaaOS.iso.sha256
          md5sum TaaOS*.iso > TaaOS.iso.md5
      
      - name: Update version.json
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          ISO_URL="https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/TaaOS-v${VERSION}.iso"
          SHA256=$(cat TaaOS.iso.sha256 | awk '{print $1}')
          
          jq -n \
            --arg version "$VERSION" \
            --arg date "$(date -I)" \
            --arg url "$ISO_URL" \
            --arg sha "$SHA256" \
            '{
              current_version: $version,
              release_date: $date,
              download_url: $url,
              checksum: {sha256: $sha},
              update_available: true,
              update_type: "minor",
              breaking_changes: false
            }' > releases/version.json
          
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add releases/version.json
          git commit -m "Update version.json for ${{ github.ref_name }}"
          git push
      
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            TaaOS*.iso
            TaaOS.iso.sha256
            TaaOS.iso.md5
          generate_release_notes: true
          body: |
            ## TaaOS ${{ github.ref_name }}
            
            ### Download
            - [TaaOS ISO](https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/TaaOS-${{ github.ref_name }}.iso)
            
            ### Checksums
            See attached .sha256 and .md5 files
            
            ### Changelog
            See [CHANGELOG.md](CHANGELOG.md)
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 📋 BÖLÜM 4: KULLANIM DÖKÜMANTASYONU

### 4.1 Release Süreci

```bash
# 1. Değişiklikleri commit et
git add .
git commit -m "feat: yeni özellik eklendi"

# 2. Changelog güncelle
# CHANGELOG.md dosyasını düzenle

# 3. Tag oluştur (Semantic Versioning)
git tag v1.0.0
git push origin v1.0.0

# 4. GitHub Actions otomatik olarak:
#    - ISO build edecek
#    - Testleri çalıştıracak
#    - Release oluşturacak
#    - version.json güncelleyecek

# 5. Kullanıcılar otomatik güncellenecek:
#    - Boot'ta güncelleme kontrolü
#    - Yeni versiyon bulunca bildirim
#    - Tek tıkla güncelleme
```

### 4.2 Test Çalıştırma

```bash
# Tüm testleri çalıştır
sudo ./tests/run-all-tests.sh

# Sadece boot testi
sudo ./tests/integration/01-boot-test.sh

# Sadece update testi
sudo ./tests/integration/05-update-test.sh

# Test sonuçlarını görüntüle
cat test-results/test-results-*.log
firefox test-results/report-*.html
```

---

## 🎯 ÖZET: YAPMAN GEREKENLER

### Adım 1: Repository Yapısını Düzenle
```bash
cd TaaOS/
mkdir -p releases tests/{integration,unit,helpers} scripts/{system,build}
mv build.sh compile_kernel.sh scripts/build/
```

### Adım 2: Update System'i Ekle
```bash
# Client script'i kopyala
cp [yukarıdaki taaos-update-client.sh] scripts/system/

# Systemd servislerini ekle
cp [yukarıdaki .service ve .timer dosyaları] config/includes.chroot/etc/systemd/system/

# Build sırasında aktif et
# Hook script'i ekle
```

### Adım 3: Test Suite'i Kur
```bash
# Test scriptlerini kopyala
cp [yukarıdaki test scriptleri] tests/

# Çalıştırılabilir yap
chmod +x tests/**/*.sh
```

### Adım 4: GitHub Actions Ekle
```bash
mkdir -p .github/workflows
cp [yukarıdaki workflow dosyaları] .github/workflows/
```

### Adım 5: İlk Release
```bash
git add .
git commit -m "feat: auto-update system ve test suite eklendi"
git push

# Tag oluştur
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions çalışacak ve release oluşturacak
```

### Adım 6: version.json Manuel Oluştur (İlk kez)
```bash
cat > releases/version.json << 'EOF'
{
  "current_version": "1.0.0",
  "release_date": "2026-01-29",
  "download_url": "https://github.com/taasezer/TaaOS/releases/download/v1.0.0/TaaOS-v1.0.0.iso",
  "checksum": {
    "sha256": "BURAYA_ISO_SHA256_KOYULACAK"
  },
  "update_available": false,
  "update_type": "major",
  "breaking_changes": false
}
EOF

git add releases/version.json
git commit -m "feat: initial version.json"
git push
```

---

## ✅ KONTROL LİSTESİ

Build öncesi:
- [ ] releases/version.json mevcut
- [ ] tests/run-all-tests.sh çalışır durumda
- [ ] scripts/system/taaos-update-client.sh ISO'ya embed ediliyor
- [ ] Systemd servisleri aktif

Build sonrası:
- [ ] `sudo ./tests/run-all-tests.sh` çalıştır
- [ ] Tüm testler PASS
- [ ] ISO QEMU'da boot oluyor
- [ ] Update check çalışıyor

Release sonrası:
- [ ] GitHub Release oluştu
- [ ] ISO indirilebilir
- [ ] version.json güncellendi
- [ ] Eski versiyondan yeni versiyona güncelleme çalışıyor

---

Sana GitHub-based, otomatik güncellenen, kapsamlı test edilen bir sistem mimarisi sundum.

**Soru:** Hangi kısmını önce implemente etmek istersin? Update system mi, test suite mi, yoksa GitHub Actions mı?
