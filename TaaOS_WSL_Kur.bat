@echo off
color 0A
title TaaOS WSL Kurulum Araci

echo ========================================================
echo               TaaOS WSL Kurulum Araci
echo ========================================================
echo.

:: Check if tarball exists
if not exist "TaaOS-WSL.tar.gz" (
    echo [HATA] TaaOS-WSL.tar.gz dosyasi bulunamadi!
    echo Lutfen bu kurulum dosyasini TaaOS-WSL.tar.gz ile ayni klasore koyun.
    pause
    exit /b 1
)

:: Define installation path
set "INSTALL_DIR=%LOCALAPPDATA%\TaaOS_WSL"

:: Check if already installed
wsl --list --quiet | findstr /I "TaaOS" >nul
if %ERRORLEVEL% equ 0 (
    echo [UYARI] TaaOS zaten WSL uzerinde kurulu gorunuyor.
    echo Yeniden kurmak isterseniz once eskisini silmeniz gerekir:
    echo wsl --unregister TaaOS
    echo.
    choice /C EH /M "Mevcut TaaOS silinip sifirdan kurulsun mu?"
    if errorlevel 2 goto exit
    if errorlevel 1 (
        echo.
        echo Eski TaaOS siliniyor...
        wsl --unregister TaaOS
    )
)

echo.
echo TaaOS, Windows sisteminize kuruluyor. Lutfen bekleyin...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Import the tarball
wsl --import TaaOS "%INSTALL_DIR%" "TaaOS-WSL.tar.gz"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================================
    echo  KURULUM BASARILI! TaaOS artik bilgisayarinizda!
    echo ========================================================
    echo.
    echo Hemen baslamak icin klavyeden bir tusa basin...
    pause >nul
    wsl -d TaaOS
) else (
    echo.
    echo [HATA] Kurulum sirasinda bir sorun olustu. WSL kurulu olmayabilir.
    echo Lutfen once "wsl --install" komutuyla WSL'yi aktif ettiginizden emin olun.
    pause
)

:exit
