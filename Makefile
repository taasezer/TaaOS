# TaaOS Master Makefile
# Handles the installation of all TaaOS components to the system
NAME = TaaOS Kernel
VERSION = 6
PATCHLEVEL = 18
SUBLEVEL = 0
EXTRAVERSION = -rc7-taaos

DESTDIR ?= /
PREFIX ?= /usr
LIBDIR ?= $(PREFIX)/lib/taaos
BINDIR ?= $(PREFIX)/bin
SYSCONFDIR ?= /etc
DATADIR ?= $(PREFIX)/share

.PHONY: install

install:
	# 1. Create Directories
	install -d $(DESTDIR)$(LIBDIR)
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(SYSCONFDIR)/taaos
	install -d $(DESTDIR)$(SYSCONFDIR)/systemd/system
	install -d $(DESTDIR)$(DATADIR)/applications
	install -d $(DESTDIR)$(DATADIR)/taaos/branding

	# 2. Install System Scripts (The "Brain" components)
	install -m 755 taaos/system/taaos-neural-engine.py $(DESTDIR)$(LIBDIR)/
	install -m 755 taaos/system/taaos-brain.py $(DESTDIR)$(LIBDIR)/
	install -m 755 taaos/system/taaos-watchdog.py $(DESTDIR)$(LIBDIR)/

	# 3. Install Executables & Tools
	install -m 755 taaos/desktop/tools/taaos-voice-control.py $(DESTDIR)$(LIBDIR)/
	install -m 755 taaos/desktop/tools/taaos-ai-gui $(DESTDIR)$(BINDIR)/
	install -m 755 taaos/bin/ai $(DESTDIR)$(BINDIR)/
	
	# 4. Install Setup Scripts
	install -m 755 taaos/scripts/setup-ai.sh $(DESTDIR)$(BINDIR)/taaos-setup-ai
	install -m 755 taaos/scripts/setup-n8n.sh $(DESTDIR)$(BINDIR)/taaos-setup-n8n
	install -m 755 taaos/scripts/setup-dev-env.sh $(DESTDIR)$(BINDIR)/taaos-setup-dev-env
	install -m 755 taaos/scripts/setup-locale.sh $(DESTDIR)$(BINDIR)/taaos-setup-locale
	install -m 755 taaos/scripts/firstboot.sh $(DESTDIR)$(BINDIR)/taaos-firstboot

	# 5. Install Systemd Services
	install -m 644 taaos/system/taaos-neural-engine.service $(DESTDIR)$(SYSCONFDIR)/systemd/system/
	install -m 644 taaos/system/taaos-brain.service $(DESTDIR)$(SYSCONFDIR)/systemd/system/
	install -m 644 taaos/system/taaos-watchdog.service $(DESTDIR)$(SYSCONFDIR)/systemd/system/
	install -m 644 taaos/system/taaos-firstboot.service $(DESTDIR)$(SYSCONFDIR)/systemd/system/

	# 6. Install Desktop Entries
	install -m 644 taaos/desktop/applications/n8n.desktop $(DESTDIR)$(DATADIR)/applications/
	install -m 644 taaos/desktop/autostart/taaos-voice.desktop $(DESTDIR)$(SYSCONFDIR)/xdg/autostart/

	# 7. Install Branding
	install -m 644 taaos/branding/logo/taaos-header.png $(DESTDIR)$(DATADIR)/taaos/branding/

	@echo "TaaOS System Components Installed Successfully!"
