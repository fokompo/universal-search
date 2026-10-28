#!/usr/bin/env bash
find_browser() {
    local desktop=""
    if [[ -n "${browser_choice:-}" ]]; then
        command -v "$browser_choice" || return 1
        return 0
    fi
    desktop="$(xdg-settings get default-web-browser 2>/dev/null || true)"
    [[ -n "$desktop" ]] ||
        desktop="$(xdg-mime query default x-scheme-handler/https 2>/dev/null || true)"
    desktop="${desktop,,}"

    case "$desktop" in
        *firefox*) command -v firefox || command -v firefox-esr || true ;;
        *librewolf*) command -v librewolf || true ;;
        *floorp*) command -v floorp || true ;;
        *brave*) command -v brave-browser || command -v brave || true ;;
        *chromium*) command -v chromium || command -v chromium-browser || true ;;
        *google-chrome*) command -v google-chrome-stable || command -v google-chrome || true ;;
        *vivaldi*) command -v vivaldi-stable || command -v vivaldi || true ;;
        *opera*) command -v opera || true ;;
        *edge*) command -v microsoft-edge-stable || command -v microsoft-edge || true ;;
        *)
            command -v firefox ||
            command -v chromium ||
            command -v brave-browser ||
            command -v google-chrome-stable ||
            command -v vivaldi ||
            command -v librewolf ||
            command -v floorp ||
            command -v opera ||
            true
            ;;
    esac
}

available_browsers() {
    local candidate
    browser_candidates=("")
    for candidate in firefox firefox-esr librewolf floorp brave-browser brave chromium chromium-browser google-chrome-stable google-chrome vivaldi microsoft-edge-stable opera; do
        command -v "$candidate" >/dev/null 2>&1 && browser_candidates+=("$candidate")
    done
}

browser_label() {
    if [[ -n "${browser_choice:-}" ]]; then printf '%s' "$browser_choice"; else printf '%s' 'System default'; fi
}

private_flag_for_browser() {
    case "${1##*/}" in
        firefox|firefox-esr|librewolf|floorp) printf '%s' '--private-window' ;;
        brave|brave-browser|chromium|chromium-browser|google-chrome|google-chrome-stable|vivaldi|vivaldi-stable)
            printf '%s' '--incognito' ;;
        microsoft-edge|microsoft-edge-stable) printf '%s' '--inprivate' ;;
        opera|opera-stable) printf '%s' '--private' ;;
        *) return 1 ;;
    esac
}

private_browser_label() {
    local browser flag
    browser="$(find_browser)" || browser=""
    [[ -n "$browser" ]] || { printf '%s' 'No supported browser'; return 1; }
    flag="$(private_flag_for_browser "$browser")" || { printf '%s' "Unsupported: ${browser##*/}"; return 1; }
    printf '%s' "${browser##*/} ready"
}

cycle_browser() {
    local current=0 i
    available_browsers
    for ((i=0; i<${#browser_candidates[@]}; i++)); do
        [[ "${browser_candidates[i]}" == "$browser_choice" ]] && current=$i
    done
    browser_choice="${browser_candidates[$(((current + 1) % ${#browser_candidates[@]}))]}"
    write_settings
}

open_target() {
    local target="$1" use_private="${2:-0}" browser flag
    OPEN_ERROR=""
    if (( ! use_private )); then
        if [[ -n "${browser_choice:-}" ]]; then
            browser="$(find_browser)" || { printf 'Browser not found: %s\n' "$browser_choice" >&2; return 1; }
            "$browser" "$target" >/dev/null 2>&1 &
            return 0
        fi
        xdg-open "$target" >/dev/null 2>&1 &
        return 0
    fi

    browser="$(find_browser)"
    if [[ -z "$browser" ]]; then
        OPEN_ERROR='Private mode needs a supported browser. Press B to choose Firefox, Chromium, Brave or another supported browser.'
        printf '%s\n' "$OPEN_ERROR" >&2
        return 1
    fi

    flag="$(private_flag_for_browser "$browser")" || {
        OPEN_ERROR="Private mode is not configured for ${browser##*/}. Press B to choose a supported browser."
        printf '%s\n' "$OPEN_ERROR" >&2
        return 1
    }

    "$browser" "$flag" "$target" >/dev/null 2>&1 &
}
