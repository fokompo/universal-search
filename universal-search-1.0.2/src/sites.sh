#!/usr/bin/env bash

sites=(google youtube wiki github reddit ddg mdn arch maps images bing brave npm pypi rust)
labels=("Google" "YouTube" "Wikipedia" "GitHub" "Reddit" "DuckDuckGo" "MDN Web Docs" "Arch Wiki" "Google Maps" "Google Images" "Bing" "Brave Search" "npm" "PyPI" "Rust Docs")
aliases=(g yt wiki gh reddit ddg mdn arch maps images bing brave npm pypi rust)
site_groups=(Web Media Knowledge Developer Community Web Developer Knowledge Maps Media Web Web Developer Developer Knowledge)
site_urls=(
    'https://www.google.com/search?q='
    'https://www.youtube.com/results?search_query='
    'https://en.wikipedia.org/w/index.php?search='
    'https://github.com/search?q='
    'https://www.reddit.com/search/?q='
    'https://duckduckgo.com/?q='
    'https://developer.mozilla.org/en-US/search?q='
    'https://wiki.archlinux.org/index.php?search='
    'https://www.google.com/maps/search/?api=1&query='
    'https://www.google.com/search?tbm=isch&q='
    'https://www.bing.com/search?q='
    'https://search.brave.com/search?q='
    'https://www.npmjs.com/search?q='
    'https://pypi.org/search/?q='
    'https://doc.rust-lang.org/std/?search='
)

# Optional user entries: site|id|label|alias|URL-prefix|group
if [[ -r "$CONFIG_FILE" ]]; then
    while IFS='|' read -r kind id label alias prefix group || [[ -n "${kind:-}" ]]; do
        [[ -z "${kind:-}" || "$kind" == \#* ]] && continue
        if [[ "$kind" != site ]]; then
            # Accept the original four-column format as well.
            prefix="$alias"
            alias="$label"
            label="$id"
            id="$kind"
            group="Custom"
        fi
        [[ "$id" =~ ^[a-zA-Z0-9_-]+$ && -n "${label:-}" && -n "${alias:-}" && "${prefix:-}" =~ ^https?://[^[:space:]]*$ ]] || continue
        [[ -n "${group:-}" ]] || group=Custom
        exists=0
        for current in "${sites[@]}" "${aliases[@]}"; do
            [[ "${current,,}" == "${id,,}" || "${current,,}" == "${alias,,}" ]] && exists=1
        done
        (( exists )) && continue
        sites+=("${id,,}")
        labels+=("$label")
        aliases+=("${alias,,}")
        site_groups+=("$group")
        site_urls+=("$prefix")
    done < "$CONFIG_FILE"
fi

favorite_ids=(google github youtube)
load_favorites_file

url_for() {
    local needle="${1,,}" i
    for ((i=0; i<${#sites[@]}; i++)); do
        if [[ "$needle" == "${sites[i]}" || "$needle" == "${aliases[i]}" ]]; then
            printf '%s' "${site_urls[i]}"
            return 0
        fi
    done
    return 1
}

is_favorite() {
    local needle="${1,,}" item
    for item in "${favorite_ids[@]}"; do
        [[ "${item,,}" == "$needle" ]] && return 0
    done
    return 1
}

toggle_favorite() {
    local idx="$1" id="${sites[$1]}" item found=0
    local -a next=()
    for item in "${favorite_ids[@]}"; do
        if [[ "${item,,}" == "$id" || "${item,,}" == "${aliases[idx]}" ]]; then
            found=1
        else
            next+=("$item")
        fi
    done
    if (( found == 0 )); then next+=("$id"); fi
    favorite_ids=("${next[@]}")
    save_favorites
}

site_index() {
    local needle="${1,,}" i
    for ((i=0; i<${#sites[@]}; i++)); do
        [[ "$needle" == "${sites[i]}" || "$needle" == "${aliases[i]}" ]] && { printf '%s' "$i"; return 0; }
    done
    return 1
}

add_custom_site() {
    local id="${1:-}" label="${2:-}" alias="${3:-}" prefix="${4:-}" group="${5:-Custom}"
    local normalized_id="${id,,}" normalized_alias="${alias,,}" current

    [[ "$id" =~ ^[a-zA-Z0-9_-]+$ ]] || { printf 'Site ID must contain only letters, numbers, _ or -.\n' >&2; return 2; }
    [[ -n "$label" && "$label" != *'|'* && "$label" != *$'\n'* ]] || { printf 'Site name must be non-empty and cannot contain | or a newline.\n' >&2; return 2; }
    [[ "$alias" =~ ^[a-zA-Z0-9_-]+$ ]] || { printf 'Alias must contain only letters, numbers, _ or -.\n' >&2; return 2; }
    [[ "$prefix" =~ ^https?://[^[:space:]\|]*$ ]] || { printf 'URL prefix must start with http:// or https:// and contain no spaces or |.\n' >&2; return 2; }
    [[ -n "$group" && "$group" != *'|'* && "$group" != *$'\n'* ]] || { printf 'Group must be non-empty and cannot contain | or a newline.\n' >&2; return 2; }

    for current in "${sites[@]}" "${aliases[@]}"; do
        if [[ "${current,,}" == "$normalized_id" || "${current,,}" == "$normalized_alias" ]]; then
            printf 'Site ID or alias already exists: %s\n' "$current" >&2
            return 2
        fi
    done

    mkdir -p -- "$CONFIG_DIR" || { printf 'Could not create config directory: %s\n' "$CONFIG_DIR" >&2; return 1; }
    printf 'site|%s|%s|%s|%s|%s\n' "$normalized_id" "$label" "$normalized_alias" "$prefix" "$group" >> "$CONFIG_FILE" || {
        printf 'Could not update site config: %s\n' "$CONFIG_FILE" >&2
        return 1
    }
    printf 'Added %s (%s) to %s\n' "$label" "$normalized_alias" "$CONFIG_FILE"
}

add_custom_site_interactive() {
    local id label alias prefix group
    [[ -t 0 ]] || { printf 'Interactive site setup needs a terminal. Pass the site details as arguments.\n' >&2; return 2; }
    read -r -p 'Site ID (for example: stackoverflow): ' id || return 2
    read -r -p 'Display name: ' label || return 2
    read -r -p 'Short alias (for example: so): ' alias || return 2
    read -r -p 'Search URL prefix (query is appended): ' prefix || return 2
    read -r -p 'Group [Custom]: ' group || return 2
    add_custom_site "$id" "$label" "$alias" "$prefix" "${group:-Custom}"
}

build_group_names() {
    groups=(All Favorites)
    local group found existing
    for group in "${site_groups[@]}"; do
        found=0
        for existing in "${groups[@]}"; do [[ "${existing,,}" == "${group,,}" ]] && found=1; done
        (( found )) || groups+=("$group")
    done
}
