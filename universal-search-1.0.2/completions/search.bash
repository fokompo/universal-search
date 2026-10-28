_universal_search_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}" config_file="${XDG_CONFIG_HOME:-$HOME/.config}/universal-search/sites.conf"
    local kind id label alias prefix group
    local -a words=(google g youtube yt wiki github gh reddit ddg mdn arch maps images bing brave npm pypi rust --help --private --print-url --group --favorites --browser --no-color)
    if [[ -r "$config_file" ]]; then
        while IFS='|' read -r kind id label alias prefix group || [[ -n "${kind:-}" ]]; do
            [[ -z "${kind:-}" || "$kind" == \#* ]] && continue
            if [[ "$kind" == site ]]; then
                [[ -n "${id:-}" ]] && words+=("$id")
                [[ -n "${alias:-}" ]] && words+=("$alias")
                [[ -n "${group:-}" ]] && words+=("$group")
            else
                # Backward-compatible id|label|alias|URL-prefix entries.
                words+=("$kind" "${label:-}")
            fi
        done < "$config_file"
    fi
    COMPREPLY=( $(compgen -W "${words[*]}" -- "$cur") )
}
complete -F _universal_search_complete search s S Search
