#!/bin/bash
# find-up-tree.sh: search parents for given name, print relative path

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'



export FindAll=false # Change with -a|--all
NoStubs=1

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

stub() {
    # Print debug output to stderr.  Call like this:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    [[ -n $NoStubs ]] && return
    builtin echo -ne "\n  <<< STUB" >&2
    for arg in "$@"; do
        echo -n "[${arg}] " >&2
    done
    echo " >>> " >&2
}

find_up() {
    [[ -n "$1" ]] \
        || exit 1
    [[ -e "$1" ]] && {
        echo -n "$1"
        exit 0
    }
    (
        [[ "$PWD" == "/" ]] && exit 1
        cd ..
        res=$(find_up "$1")
        [[ -n $res ]] && {
            echo -n ../${res};
                exit 0;
        }
        exit 1
    ) || exit 1
}

main() {
    local searchName nextUp="" foundCount=0 res prefix=""
    stub "${FUNCNAME[0]}.${LINENO}" START pwd= $PWD args= "$@"
    while [[ -n "$1" ]]; do
        case "$1" in
            -x) set -x;;
            --all|-a) FindAll=true;;
            *)
                [[ -n "$searchName" ]] && die "Unknown arg $1"
                searchName="$1"
                shift
                ;;
        esac
        shift
    done
    stub "${FUNCNAME[0]}.${LINENO}" ARGS searchName= $searchName
    [[ -n "$searchName" ]] \
        || die "No search name specified"
    while true; do
        echo -n "$prefix"; find_up "${searchName}"
        exit




        # TODO:  find and fix the recursion problems of find-all
        #  ------------------ DISABLED CODE BELOW --------------
        res=$?
        [[ $res -eq 0 ]] \
            && (( ++foundCount ))
        $FindAll \
            || exit $res
        stub "${FUNCNAME[0]}.${LINENO}" AA res= $res foundCount= $foundCount FindAll= $FindAll nextUp= "$nextUp" prefix= "$prefix"

        [[ ${#nextUp} == 1 ]] && {
            # No more dirs above us:
            [[ $foundCount -gt 0 ]];
            exit
        }
        local nextUp=$( readlink -f $( find_up "${searchName}" ))
        stub "${FUNCNAME[0]}.${LINENO}" BB nextUp= $nextUp
        nextUp=$(dirname -- ${nextUp})
        stub "${FUNCNAME[0]}.${LINENO}" CC nextUp= $nextUp
        nextUp=$(dirname -- ${nextUp})
        stub "${FUNCNAME[0]}.${LINENO}" DD nextUp= $nextUp

        [[ ${#nextUp} -lt 2 ]] && { \
            [[ $foundCount -gt 0 ]];
            exit
        }
        prefix="../${prefix}"
        stub "${FUNCNAME[0]}.${LINENO}" EE res= $res foundCount= $foundCount FindAll= $FindAll nextUp= "$nextUp" prefix= "$prefix"
        cd $next_up
    done
}

set +u
[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
