#!/usr/bin/env bash
urlencode() {
    local LC_ALL=C input="$1" out="" c hex i
    for ((i=0; i<${#input}; i++)); do
        c="${input:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) out+="$c" ;;
            *) printf -v hex '%%%02X' "'$c"; out+="$hex" ;;
        esac
    done
    printf '%s' "$out"
}

is_url() {
    [[ "$1" =~ ^https?://[^[:space:]]+$ ]]
}
