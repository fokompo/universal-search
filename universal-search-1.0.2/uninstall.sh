#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${EUID}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then exec sudo bash "$0" "$@"; fi
    echo "Error: root privileges or sudo are required." >&2
    exit 1
fi
APP_DIR=/usr/local/lib/universal-search
BIN_DIR=/usr/local/bin
SHARE_DIR=/usr/local/share
rm -f "$BIN_DIR/search" "$BIN_DIR/s" "$BIN_DIR/S" "$BIN_DIR/Search"
rm -rf "$APP_DIR"
rm -f "$SHARE_DIR/bash-completion/completions/search" \
      "$SHARE_DIR/zsh/site-functions/_universal-search" \
      "$SHARE_DIR/doc/universal-search/sites.conf.example"
printf 'Universal Search removed. User settings and data were kept.\n'
