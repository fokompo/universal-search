#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        exec sudo bash "$0" "$@"
    fi
    echo "Помилка: потрібні root-права або sudo." >&2
    exit 1
fi

APP_DIR="/usr/local/lib/universal-search"
BIN_DIR="/usr/local/bin"

rm -f "$BIN_DIR/s" "$BIN_DIR/S" \
      "$BIN_DIR/search" "$BIN_DIR/Search"
rm -rf "$APP_DIR"

echo "Universal Search видалено."
echo "Файли проєкту та репозиторій Git не видалялися."
