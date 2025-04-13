#!/bin/bash
# await-no-locks.sh
# Given a list of lock names, poll for .lock files and block
# until they're all gone

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

[[ -z ${sourceMe} ]] && {
    locknames=()
    lockdir="$PWD"
    while [[ -n $1 ]]; do
        case "$1" in
            --dir) lockdir="$2" ; shift ;;
            *) locknames+=( $1 ) ;;
        esac
        shift
    done
    [[ ${#locknames[@]} -eq 0 ]] \
        && exit 0
    cd ${lockdir} \
        || exit 0
    lockargs=$( printf "%s.lock " ${locknames[@]} )
    while true; do
        locks_remaining=$( ls $lockargs 2>/dev/null | wc -w)
        [[ $locks_remaining -gt 0 ]] && {
            sleep 1;
            continue;
        }
        exit 0
    done
    builtin exit
}
command true
