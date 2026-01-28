#!/bin/bash
# =============================================================================
# TaaOS Live Session Welcome Script
# =============================================================================
# Shows a welcome dialog when booting into live mode
# =============================================================================

# Check if running in live mode
if [ -f /run/live/medium ]; then
    IS_LIVE=true
else
    IS_LIVE=false
fi

# Only show welcome if in live mode and not installed
if [ "$IS_LIVE" = true ] && [ -f /etc/taaos-live-installer ]; then
    # Wait for desktop to be ready
    sleep 3
    
    # Show welcome dialog using zenity or xdialog
    if command -v zenity &> /dev/null; then
        zenity --info \
            --title="TaaOS'a Hoş Geldiniz!" \
            --text="<b>TaaOS Live Session</b>\n\nBu bir canlı oturumdur. TaaOS'u bilgisayarınıza kurmak için masaüstündeki <b>'Install TaaOS'</b> simgesine tıklayın.\n\n<b>Kullanıcı:</b> engineer\n<b>Şifre:</b> live\n\n<i>TaaOS - Professional Linux for Engineers</i>" \
            --width=400 \
            --ok-label="Tamam" \
            2>/dev/null &
    elif command -v xmessage &> /dev/null; then
        xmessage -center -buttons "Tamam:0" \
            "TaaOS'a Hoş Geldiniz!\n\nBu bir canlı oturumdur.\nTaaOS'u kurmak için masaüstündeki 'Install TaaOS' simgesine tıklayın.\n\nKullanıcı: engineer\nŞifre: live" &
    fi
fi
