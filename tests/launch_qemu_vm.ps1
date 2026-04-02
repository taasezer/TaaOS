# =============================================================================
# TaaOS QEMU Test Script
# =============================================================================
# Bu betik QEMU kullanarak TaaOS iso dosyasını 45 GB Sanal Disk ve 8 GB RAM
# ile başlatır.
# 
# GEREKSİNİM: Windows'ta QEMU kurulu olmalı ve Sistem PATH'ine eklenmiş olmalı.
# İndirmek için: https://qemu.weilnetz.de/w64/ adresinden kurabilirsiniz.
# =============================================================================

$isoPath = "c:\Users\tahas\TaaOS\TaaOS.iso"
$qcowPath = "c:\Users\tahas\TaaOS\taaos_qemu_disk.qcow2"

# QEMU Yollarını kontrol et (Varsayılan kurulum dizini)
$qemuImg = "qemu-img"
$qemuSys = "qemu-system-x86_64"

if (Test-Path "C:\Program Files\qemu\qemu-img.exe") {
    $qemuImg = "C:\Program Files\qemu\qemu-img.exe"
    $qemuSys = "C:\Program Files\qemu\qemu-system-x86_64.exe"
}

# QEMU Yüklü mü Kontrolü
try {
    & $qemuImg --version > $null
} catch {
    Write-Host "HATA: QEMU sistemde bulunamadı!" -ForegroundColor Red
    Write-Host "Lütfen https://qemu.weilnetz.de/w64/ adresinden QEMU'yu kurun."
    Write-Host "Veya kurarken 'Add to Path' seçeneğini işaretleyin."
    Exit
}

# 1. 45 GB QCOW2 Sanal Disk Oluştur (Eğer yoksa veya silinmesi istenirse)
if (Test-Path $qcowPath) {
    $response = Read-Host "Mevcut Sanal Disk bulundu, silinip sıfırdan oluşturulsun mu? (Y/N)"
    if ($response -match "Y|y") {
        Remove-Item $qcowPath -Force
        Write-Host "45 GB QEMU Sanal Diski Oluşturuluyor..."
        & $qemuImg create -f qcow2 $qcowPath 45G
    }
} else {
    Write-Host "45 GB QEMU Sanal Diski Oluşturuluyor..."
    & $qemuImg create -f qcow2 $qcowPath 45G
}

# 2. QEMU'yu Başlat (8 GB RAM, KVM/WHPX Donanım Hızlandırma Desteği)
Write-Host "QEMU başlatılıyor... (8 GB RAM)"
Write-Host "Kurulum bitince ISO'suz başlatmak için kodu düzenleyebilirsin."

# Windows'ta WHPX hızlandırmayı deniyoruz, yoksa TCG (yazılım) ile başlatılır
$qemuArgs = @(
    "-m", "8192",                 # 8 GB RAM
    "-smp", "4",                  # 4 Çekirdek İşlemci
    "-drive", "file=$qcowPath,format=qcow2",  # 45GB Disk
    "-cdrom", "$isoPath",         # TaaOS ISO
    "-boot", "d",                 # Önce CDROM'dan (ISO) boot et
    "-vga", "virtio",             # Daha iyi grafik performansı
    "-display", "sdl",            # Standart pencere ekranı
    "-usb",                       # USB Aktifleştirme
    "-device", "usb-tablet"       # Mause kaymasını çözen (Absolute) cihaz
)

# QEMU'yu çalıştır
& $qemuSys $qemuArgs
