#!/bin/bash
# vi-mode.sh

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

stub() {
    # Print debug output to stderr.  Recommend to call like this:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    [[ -n $NoStubs ]] && return
    [[ -n $__stub_counter ]] && (( __stub_counter++  )) || __stub_counter=1
    {
        builtin printf "  <=< STUB(%d:%s)" $__stub_counter "$(basename $scriptName)"
        builtin printf "[%s] " "$@"
        builtin printf " >=> \n"
    } >&2
}

set_vi_mode() {
    local mode=$1
    ln -sf ${scriptDir}/inputrc-vi-$mode ${HOME}/.inputrc
    echo "vi mode is now $mode, restart shell."
}

do_help() {
    echo "$(basename $scriptName) on|off"
}

main() {
    while [[ -n $1 ]]; do
        case $1 in
            on) set_vi_mode on ; return ;;
            off) set_vi_mode off ; return ;;
        esac
        shift
    done
    do_help
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
