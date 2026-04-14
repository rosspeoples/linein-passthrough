#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT=/opt/linein-passthrough

usage() {
  cat <<'EOF'
Usage: linein-passthrough-container <command> [options]

Commands:
  install [--with-wireplumber-config] [--without-service]
  uninstall [--keep-wireplumber-config]
  status
  help

This image is an immutable-OS friendly installer wrapper.
Run it with your real HOME, XDG_RUNTIME_DIR, and DBUS_SESSION_BUS_ADDRESS mounted from the host user session.
EOF
}

require_home() {
  if [[ -z "${HOME:-}" || ! -d "${HOME}" ]]; then
    printf 'HOME must point to a mounted host home directory.\n' >&2
    exit 1
  fi
}

print_plasma_note() {
  printf 'Note: KDE Plasma must have "Show Virtual Devices" enabled for Line-In Passthrough to be visible.\n'
}

cmd_install() {
  require_home
  print_plasma_note
  exec "${PROJECT_ROOT}/bin/linein-passthrough-install" "$@"
}

cmd_uninstall() {
  require_home
  exec "${PROJECT_ROOT}/bin/linein-passthrough-uninstall" "$@"
}

cmd_status() {
  require_home
  export LINEIN_PASSTHROUGH_REFRESH_BIN="${HOME}/.local/bin/linein-passthrough-refresh"
  exec "${PROJECT_ROOT}/bin/linein-passthrough" status
}

case "${1:-help}" in
  install)
    shift
    cmd_install "$@"
    ;;
  uninstall)
    shift
    cmd_uninstall "$@"
    ;;
  status)
    shift
    cmd_status "$@"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    printf 'Unknown command: %s\n' "$1" >&2
    usage >&2
    exit 1
    ;;
esac
