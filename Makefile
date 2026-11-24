PREFIX ?= /usr
DESTDIR ?=

THEME_DIR := $(DESTDIR)$(PREFIX)/share/sddm/themes/noctalia-blurry
BIN_DIR := $(DESTDIR)$(PREFIX)/bin
USER_UNIT_DIR := $(DESTDIR)$(PREFIX)/lib/systemd/user
SYSUSERS_DIR := $(DESTDIR)$(PREFIX)/lib/sysusers.d
TMPFILES_DIR := $(DESTDIR)$(PREFIX)/lib/tmpfiles.d
DOC_DIR := $(DESTDIR)$(PREFIX)/share/doc/sddm-noctalia-blurry
LICENSE_DIR := $(DESTDIR)$(PREFIX)/share/licenses/sddm-noctalia-blurry

.PHONY: all install uninstall

all:
	@echo "Run 'make install' or 'make DESTDIR=... install' to install sddm-noctalia-blurry."

install:
	install -d -m 0755 $(THEME_DIR) $(BIN_DIR) $(USER_UNIT_DIR) $(SYSUSERS_DIR) $(TMPFILES_DIR) $(DOC_DIR) $(LICENSE_DIR)
	install -m 0644 theme/Main.qml $(THEME_DIR)/Main.qml
	install -m 0644 theme/theme.conf $(THEME_DIR)/theme.conf
	install -m 0644 theme/metadata.desktop $(THEME_DIR)/metadata.desktop
	install -m 0755 scripts/noctalia-sddm-sync $(BIN_DIR)/noctalia-sddm-sync
	install -m 0644 systemd/noctalia-sddm-sync.service $(USER_UNIT_DIR)/noctalia-sddm-sync.service
	install -m 0644 systemd/noctalia-sddm-sync.timer $(USER_UNIT_DIR)/noctalia-sddm-sync.timer
	install -m 0644 packaging/sysusers.d/sddm-noctalia-blurry.conf $(SYSUSERS_DIR)/sddm-noctalia-blurry.conf
	install -m 0644 packaging/tmpfiles.d/sddm-noctalia-blurry.conf $(TMPFILES_DIR)/sddm-noctalia-blurry.conf
	install -m 0644 packaging/sddm.conf.d/10-noctalia-blurry.conf $(DOC_DIR)/10-noctalia-blurry.conf
	install -m 0644 LICENSE $(LICENSE_DIR)/LICENSE

uninstall:
	rm -rf $(THEME_DIR) $(DOC_DIR) $(LICENSE_DIR)
	rm -f $(BIN_DIR)/noctalia-sddm-sync
	rm -f $(USER_UNIT_DIR)/noctalia-sddm-sync.service $(USER_UNIT_DIR)/noctalia-sddm-sync.timer
	rm -f $(SYSUSERS_DIR)/sddm-noctalia-blurry.conf
	rm -f $(TMPFILES_DIR)/sddm-noctalia-blurry.conf
