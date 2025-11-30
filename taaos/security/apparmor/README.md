# TaaOS AppArmor Profiles
# Security profiles for system applications

This directory contains AppArmor profiles for:

1. taaos-browser - Firefox/Chromium hardening
2. taaos-docker - Docker daemon restrictions
3. taaos-neural-engine - AI subsystem sandboxing
4. taaos-system-services - Core service restrictions

All profiles follow the principle of least privilege and are designed
to protect the system while maintaining functionality.

To load profiles:
```bash
sudo apparmor_parser -r /etc/apparmor.d/taaos-*
```

To check status:
```bash
sudo aa-status
```
