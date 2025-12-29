TaaOS Build System - includes.chroot_before_packages
====================================================

Files placed in this directory will be copied into the OS filesystem
BEFORE any packages are installed.

Use this directory for:
1. Adding APT configuration (sources.list) required for installation.
2. Pre-seeding configuration files that packages might check heavily.
3. Placing temporary files needed during the installation phase.
