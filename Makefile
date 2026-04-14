PREFIX ?= $(HOME)/.config
BIN_DIR ?= $(HOME)/.local/bin

.PHONY: help install install-wireplumber uninstall uninstall-keep-wireplumber status enable disable refresh

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  install                  Install core project files' \
	  '  install-wireplumber      Install core files plus optional WirePlumber placeholder config' \
	  '  uninstall                Remove all installed files' \
	  '  uninstall-keep-wireplumber Remove installed files but keep the optional WirePlumber config' \
	  '  status                   Show current passthrough status' \
	  '  enable                   Enable passthrough' \
	  '  disable                  Disable passthrough' \
	  '  refresh                  Re-detect source and sink and rewrite config if needed'

install:
	./bin/linein-passthrough-install

install-wireplumber:
	./bin/linein-passthrough-install --with-wireplumber-config

uninstall:
	./bin/linein-passthrough-uninstall

uninstall-keep-wireplumber:
	./bin/linein-passthrough-uninstall --keep-wireplumber-config

status:
	./bin/linein-passthrough status

enable:
	./bin/linein-passthrough enable

disable:
	./bin/linein-passthrough disable

refresh:
	./bin/linein-passthrough refresh
