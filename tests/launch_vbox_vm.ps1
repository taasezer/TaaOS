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
& $vbox modifyvm $vmName --memory 8192 --vram 128 --ioapic on --rtcuseutc on
& $vbox createhd --filename $vdiPath --size 25000 --format VDI

Write-Host "Configuring Storage..."
& $vbox storagectl $vmName --name "SATA Controller" --add sata --controller IntelAhci
& $vbox storageattach $vmName --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $vdiPath

& $vbox storagectl $vmName --name "IDE Controller" --add ide
& $vbox storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $isoPath

Write-Host "Starting Virtual Machine..."
& $vbox startvm $vmName
