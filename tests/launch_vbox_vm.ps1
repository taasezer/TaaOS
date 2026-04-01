# =============================================================================
# TaaOS VirtualBox Test Script
# =============================================================================
# IMPORTANT: After installation, the VM must boot from HDD first (not DVD/ISO).
# This script sets boot order: 1) Disk  2) DVD  3) None  4) None
# If installation seems to "not persist", make sure the ISO is detached or
# boot order prioritizes the hard disk.
# =============================================================================

$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "TaaOS_VirtualBox_VM"
$isoPath = "c:\Users\tahas\TaaOS\TaaOS.iso"
$vdiPath = "c:\Users\tahas\TaaOS\TaaOS_VirtualBox_VM.vdi"

$existingVms = & $vbox list vms
if ($existingVms -match $vmName) {
    Write-Host "VM already exists, removing it..."
    & $vbox controlvm $vmName poweroff 2>$null
    Start-Sleep -Seconds 2
    & $vbox unregistervm $vmName --delete
}

if (Test-Path $vdiPath) {
    Remove-Item $vdiPath -Force
}

Write-Host "Creating Virtual Machine..."
& $vbox createvm --name $vmName --ostype "Linux26_64" --register
& $vbox modifyvm $vmName --memory 10000 --vram 128 --ioapic on --rtcuseutc on --mouse usbtablet
& $vbox createhd --filename $vdiPath --size 45000 --format VDI

Write-Host "Configuring Storage..."
& $vbox storagectl $vmName --name "IDE Controller" --add ide
& $vbox storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium $vdiPath
& $vbox storageattach $vmName --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium $isoPath

# CRITICAL: Set boot order — HDD first, then DVD
# This ensures that after installation, the VM boots from the installed system
Write-Host "Setting boot order: 1) Disk  2) DVD..."
& $vbox modifyvm $vmName --boot1 disk --boot2 dvd --boot3 none --boot4 none

Write-Host "Starting Virtual Machine..."
& $vbox startvm $vmName

Write-Host ""
Write-Host "=============================================="
Write-Host "  TaaOS Test VM Started"
Write-Host "=============================================="
Write-Host ""
Write-Host "After installation completes and VM reboots:"
Write-Host "  1. The VM should boot from the HDD (installed system)"
Write-Host "  2. Plymouth welcome animation should play"
Write-Host "  3. Welcome video (Welcome.mp4) plays on first boot"
Write-Host "  4. LightDM login screen should appear"
Write-Host "  5. Log in with the user you created during install"
Write-Host ""
Write-Host "If VM boots back to live ISO instead of installed system:"
Write-Host "  - Detach the ISO: VBoxManage storageattach $vmName --storagectl 'IDE Controller' --port 0 --device 0 --type dvddrive --medium emptydrive"
Write-Host "  - Or change boot order in VirtualBox Settings > System > Boot Order"
Write-Host ""
