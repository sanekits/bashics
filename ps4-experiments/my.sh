#!/bin/bash
# my.sh

scriptName="$(readlink -f "$0")"
# (if needed) scriptDir=$(command dirname -- "${scriptName}")

set -ue

#shellcheck disable=2154
#PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) ' # reference

#PS4='\033[0;33m$( _0=$?;set +e;exec 2>/dev/null;realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} \033[0;35m^$_0\033[32m ${FUNCNAME[0]:-?}()=>" )\033[;0m '  # reference

#======================================================================= TESTAREA =================================

#------------------------------------------------------------------------------------------------------------------

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}

main() {
    true
    false
    (
        set -x
        exit 221
    )
    true
    echo This script needs some content.
}

if [[ -z "${sourceMe:-}" ]]; then
    echo "entering main soon"
    main "$@"
    builtin exit
fi
command true

