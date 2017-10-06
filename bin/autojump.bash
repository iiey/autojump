export AUTOJUMP_SOURCED=1

# set user installation paths
if [[ -d ~/.autojump/ ]] && [[ $PATH != *"autojump"* ]]; then
    export PATH=~/.autojump/bin:"${PATH}"
fi


# set error file location
if [[ "$(uname)" == "Darwin" ]]; then
    export AUTOJUMP_ERROR_PATH=~/Library/autojump/errors.log
elif [[ -n "${XDG_DATA_HOME}" ]]; then
    export AUTOJUMP_ERROR_PATH="${XDG_DATA_HOME}/autojump/errors.log"
else
    export AUTOJUMP_ERROR_PATH=~/.local/share/autojump/errors.log
fi

if [[ ! -d "$(dirname ${AUTOJUMP_ERROR_PATH})" ]]; then
    mkdir -p "$(dirname ${AUTOJUMP_ERROR_PATH})"
fi


# fzf completion helper
_autojump_fzf() {
    #--stat show the jumping list with increasing weight from top to bottom
    #fzf: reverse (tac) no sort to display most recently used directories first
    autojump --stat | sed '/___/,$d' | cut -f 2 |       #use only second column
        sed '/rvm\/copy/d' |                            #ignore paths
        fzf --tac --no-sort --height 40% \
            --preview-window=right --preview="tree {} -L 1 -C | head -100"
}

# enable tab completion
#https://johnlane.ie/injecting-terminal-input.html
#to redraw line after fzf closes (printf '\e[5n')
#set -o emacs
[[ $- == *i*  ]] && bind '"\e[0n": redraw-current-line'
_autojump() {
        COMPREPLY=()
        local comps
        #use bash function to get current word
        local cur && _get_comp_words_by_ref cur

        #support fzf if available, trigger with empty input <tab>
        if [ -z "$cur" ] && type fzf &> /dev/null; then
            comps=$(_autojump_fzf)
        #otherwise use classic complete
        else
            comps=$(autojump --complete $cur)
        fi

        for i in $comps; do COMPREPLY=("${COMPREPLY[@]}" "${i}"); done
        #refresh one lines
        printf '\e[5n'
}
complete -F _autojump j


# change pwd hook
autojump_add_to_database() {
    if [[ -f "${AUTOJUMP_ERROR_PATH}" ]]; then
        (autojump --add "$(pwd)" >/dev/null 2>>${AUTOJUMP_ERROR_PATH} &) &>/dev/null
    else
        (autojump --add "$(pwd)" >/dev/null &) &>/dev/null
    fi
}

case $PROMPT_COMMAND in
    *autojump*)
        ;;
    *)
        PROMPT_COMMAND="${PROMPT_COMMAND:+$(echo "${PROMPT_COMMAND}" | awk '{gsub(/; *$/,"")}1') ; }autojump_add_to_database"
        ;;
esac


# default autojump command
j() {
    if [[ -z ${1} ]] && type fzf &> /dev/null; then
        local dir=$(_autojump_fzf)
        [ -d "$dir" ] && cd "$dir"
        return
    fi

    if [[ ${1} == -* ]] && [[ ${1} != "--" ]]; then
        autojump ${@}
        return
    fi

    output="$(autojump ${@})"
    if [[ -d "${output}" ]]; then
        cd "${output}"
    else
        echo "autojump: directory '${@}' not found"
        echo "\n${output}\n"
        echo "Try \`autojump --help\` for more information."
        false
    fi
}


# jump to child directory (subdirectory of current path)
jc() {
    if [[ ${1} == -* ]] && [[ ${1} != "--" ]]; then
        autojump ${@}
        return
    else
        j $(pwd) ${@}
    fi
}


# open autojump results in file browser
jo() {
    if [[ ${1} == -* ]] && [[ ${1} != "--" ]]; then
        autojump ${@}
        return
    fi

    if [[ ${1} == "." ]]; then
        output=$(pwd)
    else
        output="$(autojump ${@})"
    fi

    if [[ -d "${output}" ]]; then
        case ${OSTYPE} in
            linux*)
                xdg-open "${output}" &> /dev/null || echo "Error: xdg-open could not open ${output}"
                ;;
            darwin*)
                open "${output}"
                ;;
            cygwin)
                cygstart "" $(cygpath -w -a ${output})
                ;;
            *)
                echo "Unknown operating system: ${OSTYPE}." 1>&2
                ;;
        esac
    else
        echo "autojump: directory '${@}' not found"
        echo "\n${output}\n"
        echo "Try \`autojump --help\` for more information."
        false
    fi
}


# open autojump results (child directory) in file browser
jco() {
    if [[ ${1} == -* ]] && [[ ${1} != "--" ]]; then
        autojump ${@}
        return
    else
        jo $(pwd) ${@}
    fi
}
