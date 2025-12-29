#!/bin/bash
echo "Temizlik yapılıyor..."
find . -type f \( -name "*.o" -o -name "*.bin" -o -name "*.elf" -o -name "*.iso" -o -name "*.img" -o -name "*.map" -o -name "*.out" -o -name "*.log" \) -print -delete
echo "Bitti! Gereksiz dosyalar silindi."