#!/usr/bin/env bash
set -Eeuo pipefail

REPO="fokompo/universal-search"
BRANCH="main"
APP_DIR="/usr/local/lib/universal-search"
BIN_DIR="/usr/local/bin"
RAW_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/search"

if [[ "${EUID}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        exec sudo bash "$0" "$@"
    fi
    echo "Помилка: потрібні root-права або sudo." >&2
    exit 1
fi

for cmd in install ln rm mkdir; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Не знайдено необхідну команду: $cmd" >&2
        exit 1
    }
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

# Якщо поруч з інсталятором є search — використовуємо його.
# Інакше завантажуємо опубліковану версію з GitHub.
if [[ -f "$SCRIPT_DIR/search" ]]; then
    install -m 755 "$SCRIPT_DIR/search" "$TMP_FILE"
elif command -v curl >/dev/null 2>&1; then
    curl -fL --retry 2 "$RAW_URL" -o "$TMP_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$TMP_FILE" "$RAW_URL"
else
    echo "Встанови curl або wget і повтори спробу." >&2
    exit 1
fi

if [[ ! -s "$TMP_FILE" ]]; then
    echo "Помилка: файл search порожній." >&2
    exit 1
fi

if ! head -n 1 "$TMP_FILE" | grep -q 'bash'; then
    echo "Помилка: завантажений файл не схожий на Bash-скрипт." >&2
    exit 1
fi

mkdir -p "$APP_DIR" "$BIN_DIR"
install -m 755 "$TMP_FILE" "$APP_DIR/search"

# Нижній регістр: CLI; S: інтерактивний режим через ім'я S.
ln -sfn "$APP_DIR/search" "$BIN_DIR/search"
ln -sfn "$APP_DIR/search" "$BIN_DIR/s"
ln -sfn "$APP_DIR/search" "$BIN_DIR/S"

# Search запускає той самий файл через посилання S,
# щоб програма отримала ім'я запуску S.
cat > "$BIN_DIR/Search" <<'LAUNCHER'
#!/usr/bin/env bash
exec /usr/local/bin/S "$@"
LAUNCHER
chmod 755 "$BIN_DIR/Search"

echo
echo "Universal Search встановлено."
echo "Команди: s, S, search, Search"
echo "Якщо команда не знаходиться, перевір PATH: $BIN_DIR"
