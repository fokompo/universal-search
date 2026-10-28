#!/usr/bin/env bash

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_DIR="$CONFIG_HOME/universal-search"
CONFIG_FILE="$CONFIG_DIR/sites.conf"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
FAVORITES_FILE="$CONFIG_DIR/favorites"
DATA_DIR="$DATA_HOME/universal-search"
HISTORY_FILE="$DATA_DIR/history"
RESULTS_DIR="$DATA_DIR/results"

browser_choice="${UNIVERSAL_SEARCH_BROWSER:-}"
color_mode="auto"

load_settings() {
    local key value
    [[ -r "$SETTINGS_FILE" ]] || return 0
    while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
        case "$key" in
            browser) [[ -n "$browser_choice" ]] || browser_choice="$value" ;;
            color) [[ "$value" == always || "$value" == never || "$value" == auto ]] && color_mode="$value" ;;
        esac
    done < "$SETTINGS_FILE"
}

write_settings() {
    mkdir -p "$CONFIG_DIR" || return 1
    local tmp
    tmp="$(mktemp "$CONFIG_DIR/settings.XXXXXX")" || return 1
    {
        printf 'browser=%s\n' "$browser_choice"
        printf 'color=%s\n' "$color_mode"
    } > "$tmp"
    mv -- "$tmp" "$SETTINGS_FILE"
}

load_favorites_file() {
    [[ -r "$FAVORITES_FILE" ]] || return 0
    local -a configured=()
    mapfile -t configured < "$FAVORITES_FILE"
    favorite_ids=()
    local id found
    for id in "${configured[@]}"; do
        found=0
        for current in "${sites[@]}" "${aliases[@]}"; do
            [[ "${current,,}" == "${id,,}" ]] && found=1
        done
        (( found )) && favorite_ids+=("${id,,}")
    done
}

save_favorites() {
    mkdir -p "$CONFIG_DIR" || return 1
    local tmp id
    tmp="$(mktemp "$CONFIG_DIR/favorites.XXXXXX")" || return 1
    for id in "${favorite_ids[@]}"; do printf '%s\n' "$id"; done > "$tmp"
    mv -- "$tmp" "$FAVORITES_FILE"
}

remember_query() {
    local q="$1" old
    (( private )) && return 0
    [[ -n "$q" ]] || return 0

    mkdir -p "$DATA_DIR" || return 0
    local -a updated=()
    if [[ -f "$HISTORY_FILE" ]]; then
        while IFS= read -r old; do
            [[ "$old" == "$q" ]] || updated+=("$old")
        done < "$HISTORY_FILE"
    fi
    updated+=("$q")
    if ((${#updated[@]} > 20)); then updated=("${updated[@]: -20}"); fi
    printf '%s\n' "${updated[@]}" > "$HISTORY_FILE"
    history=("${updated[@]}")
}

load_history() {
    history=()
    [[ -f "$HISTORY_FILE" ]] && mapfile -t history < "$HISTORY_FILE"
}
