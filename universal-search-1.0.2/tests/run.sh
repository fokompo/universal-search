#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/universal-search-tests.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
export XDG_CONFIG_HOME="$TMP/config"
export XDG_DATA_HOME="$TMP/data"
mkdir -p "$XDG_CONFIG_HOME/universal-search"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_eq() { [[ "$1" == "$2" ]] || fail "$3 (got: $1; expected: $2)"; }

assert_eq "$("$ROOT/search" --print-url github 'bash arrays & loops')" \
    'https://github.com/search?q=bash%20arrays%20%26%20loops' 'URL encoding'

"$ROOT/search" --add-site test-search 'Test Search' ts 'https://test.example/search?q=' Testing >/dev/null
assert_eq "$("$ROOT/search" --print-url ts 'one two')" \
    'https://test.example/search?q=one%20two' 'CLI site registration'
if "$ROOT/search" --add-site duplicate 'Duplicate' ts 'https://duplicate.example/?q=' >/dev/null 2>&1; then
    fail 'duplicate site alias should fail'
fi
if "$ROOT/search" --add-site bad 'Bad' bad 'javascript:alert(1)' >/dev/null 2>&1; then
    fail 'non-http site prefix should fail'
fi

cat > "$XDG_CONFIG_HOME/universal-search/sites.conf" <<'CONFIG'
# kind|id|label|alias|url-prefix|group
site|example|Example Search|ex|https://example.org/find?q=|Development
legacy|Legacy Search|old|https://legacy.example/?q=
CONFIG
assert_eq "$("$ROOT/search" --print-url ex 'hello world')" \
    'https://example.org/find?q=hello%20world' 'custom site and alias'
assert_eq "$("$ROOT/search" --print-url old legacy)" \
    'https://legacy.example/?q=legacy' 'legacy site format'
assert_eq "$("$ROOT/search" --print-url --group Development hello)" \
    'https://example.org/find?q=hello' 'custom group'
group_urls="$("$ROOT/search" --print-url --group Developer hello)"
first_group_url="${group_urls%%$'\n'*}"
assert_eq "$first_group_url" \
    'https://github.com/search?q=hello' 'built-in group'

printf 'example\n' > "$XDG_CONFIG_HOME/universal-search/favorites"
assert_eq "$("$ROOT/search" --print-url --favorites test)" \
    'https://example.org/find?q=test' 'favorite sites'

plain_output="$("$ROOT/search" --no-color --help)"
[[ "$plain_output" != *$'\033'* ]] || fail 'no-color output contains ANSI escapes'

source "$ROOT/completions/search.bash"
COMP_WORDS=(search ex); COMP_CWORD=1; COMPREPLY=()
_universal_search_complete
[[ " ${COMPREPLY[*]} " == *" ex "* ]] || fail 'custom site completion'

mkdir -p "$TMP/bin"
cat > "$TMP/bin/browser-stub" <<'BROWSER'
#!/usr/bin/env bash
printf '%s\n' "$1" > "$BROWSER_CAPTURE"
BROWSER
chmod +x "$TMP/bin/browser-stub"
export BROWSER_CAPTURE="$TMP/browser-url"
PATH="$TMP/bin:$PATH" "$ROOT/search" --browser browser-stub github 'test query'
for _ in {1..20}; do [[ -s "$BROWSER_CAPTURE" ]] && break; sleep 0.05; done
assert_eq "$(<"$BROWSER_CAPTURE")" 'https://github.com/search?q=test%20query' 'browser selection'
: > "$BROWSER_CAPTURE"
printf 'browser=browser-stub\ncolor=never\n' > "$XDG_CONFIG_HOME/universal-search/settings.conf"
PATH="$TMP/bin:$PATH" "$ROOT/search" github 'saved browser'
for _ in {1..20}; do [[ -s "$BROWSER_CAPTURE" ]] && break; sleep 0.05; done
assert_eq "$(<"$BROWSER_CAPTURE")" 'https://github.com/search?q=saved%20browser' 'saved browser setting'

if "$ROOT/search" --print-url --group Missing test >/dev/null 2>&1; then
    fail 'unknown group should fail'
fi

printf 'All Universal Search tests passed.\n'
