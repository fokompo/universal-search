_universal_search_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local sites="g google yt youtube wiki gh github reddit ddg mdn arch wikiarch maps images bing brave npm pypi rust"

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "-p --private -h --help" -- "$cur") )
        return
    fi

    if (( COMP_CWORD == 1 )); then
        COMPREPLY=( $(compgen -W "$sites" -- "$cur") )
    elif (( COMP_CWORD == 2 )) &&
         [[ "${COMP_WORDS[1]}" == "-p" || "${COMP_WORDS[1]}" == "--private" ]]; then
        COMPREPLY=( $(compgen -W "$sites" -- "$cur") )
    fi
}

complete -F _universal_search_completion search s S Search
