TaaOS Build System - includes.chroot_after_packages
===================================================

Files placed in this directory will be copied into the OS filesystem
AFTER all packages have been installed.

Use this directory for:
1. Overwriting configuration files created by package installations.
2. Replacing default package assets.
3. Ensuring your config takes precedence over everything else.

Example:
    ./etc/ssh/sshd_config  -> Overwrites default SSH config
