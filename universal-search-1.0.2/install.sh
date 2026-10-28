#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/usr/local/lib/universal-search"
BIN_DIR="/usr/local/bin"
SHARE_DIR="/usr/local/share"

if [[ "${EUID}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then exec sudo bash "$0" "$@"; fi
    echo "Error: root privileges or sudo are required." >&2
    exit 1
fi

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ -x "$SOURCE_DIR/search" && -d "$SOURCE_DIR/src" ]] || {
    echo "Error: search and src/ must be next to install.sh." >&2
    exit 1
}
install -d "$APP_DIR/src" "$APP_DIR/tui" "$BIN_DIR" \
    "$SHARE_DIR/bash-completion/completions" \
    "$SHARE_DIR/zsh/site-functions" \
    "$SHARE_DIR/doc/universal-search"
install -m 755 "$SOURCE_DIR/search" "$APP_DIR/search"
install -m 644 "$SOURCE_DIR"/src/*.sh "$APP_DIR/src/"
install -m 644 "$SOURCE_DIR/tui/app.py" "$APP_DIR/tui/app.py"
install -m 644 "$SOURCE_DIR/completions/search.bash" "$SHARE_DIR/bash-completion/completions/search"
install -m 644 "$SOURCE_DIR/completions/_universal-search" "$SHARE_DIR/zsh/site-functions/_universal-search"
install -m 644 "$SOURCE_DIR/config/sites.conf.example" "$SHARE_DIR/doc/universal-search/sites.conf.example"
for name in search s S Search; do ln -sfn "$APP_DIR/search" "$BIN_DIR/$name"; done
printf 'Universal Search 1.0.6 installed. Commands: search, s, S, Search\n'
