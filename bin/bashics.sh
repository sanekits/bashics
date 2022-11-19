#!/bin/bash
# bashics.sh
#  This script can be removed if you don't need it -- and if you do
# that you should remove the entry from _symlinks_ and make-kit.mk also.

canonpath() {
    builtin type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    builtin type -t readlink &>/dev/null && {
        command readlink -f "$@"
        return
    }
    # Fallback: Ok for rough work only, does not handle some corner cases:
    ( builtin cd -L -- "$(command dirname -- $0)"; builtin echo "$(command pwd -P)/$(command basename -- $0)" )
}

scriptName="$(canonpath "$0")"
scriptDir=$(command dirname -- "${scriptName}")
script=$(basename $scriptName)

source ${scriptDir}/set_bashdebug_mode

die() {
    builtin echo "ERROR($(command basename -- ${scriptName})): $*" >&2
    builtin exit 1
}

do_help() {
    cat <<-EOF
$script --help:
---------------
set_bashdebug_mode: $(bashdebug_mode_help)
reset:  clear the terminal
\$EDITOR: set default to vi if not set already
\$MSYS: on git-bash/cygwin, enable symlinks
lsl,ll,la,lra,l,l1,lr,lg,lsg: various ls aliases
.p .- .1 .2 .3 ...: various dir-change aliases
tree-walker.sh: walk dir heirarchy, running 'command' if 'condition' met
EOF
}


stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

main() {
    do_help "$@"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
