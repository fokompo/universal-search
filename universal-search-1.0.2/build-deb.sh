#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DIST="$ROOT/dist"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/universal-search-deb.XXXXXX")"
trap 'rm -rf -- "$STAGE"' EXIT

install -d "$DIST" "$STAGE/DEBIAN" "$STAGE/usr/bin" \
    "$STAGE/usr/lib/universal-search/src" \
    "$STAGE/usr/lib/universal-search/tui" \
    "$STAGE/usr/share/bash-completion/completions" \
    "$STAGE/usr/share/zsh/site-functions" \
    "$STAGE/usr/share/doc/universal-search" \
    "$STAGE/usr/share/universal-search"
install -m 755 "$ROOT/search" "$STAGE/usr/bin/search"
install -m 644 "$ROOT"/src/*.sh "$STAGE/usr/lib/universal-search/src/"
install -m 644 "$ROOT/tui/app.py" "$STAGE/usr/lib/universal-search/tui/app.py"
install -m 644 "$ROOT/completions/search.bash" \
    "$STAGE/usr/share/bash-completion/completions/search"
install -m 644 "$ROOT/completions/_universal-search" \
    "$STAGE/usr/share/zsh/site-functions/_universal-search"
install -m 644 "$ROOT/README.md" "$ROOT/LICENSE" \
    "$STAGE/usr/share/doc/universal-search/"
install -m 644 "$ROOT/config/sites.conf.example" \
    "$STAGE/usr/share/universal-search/"
ln -s search "$STAGE/usr/bin/s"
ln -s search "$STAGE/usr/bin/S"
ln -s search "$STAGE/usr/bin/Search"
cat > "$STAGE/DEBIAN/control" <<'CONTROL'
Package: universal-search
Version: 1.0.5-1
Section: utils
Priority: optional
Architecture: all
Depends: bash, coreutils, xdg-utils, python3, python3-curses
Maintainer: fokompo <fokompo456@gmail.com>
Description: Universal terminal search
 Search Google, YouTube, GitHub, Wikipedia and more from an
 interactive terminal interface or CLI.
CONTROL

dpkg-deb --root-owner-group --build "$STAGE" \
    "$DIST/universal-search_1.0.5-1_all.deb"
