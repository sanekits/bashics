#!/bin/bash
# tree-walker.sh

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
script=$(basename $scriptName)
PS4='\033[0;33m+(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

do_help() {
    cat <<-EOF
$script '<condition-test-expression>' '<command-expression>' -d|--max-depth N   -a|--hidden -q|--quiet

   Walk the dir tree from \$CWD.  Evaluate <condition-test-expression>,
   if it succeeds then run <command-expression>.

Examples:
---------

1: Provide condition and command:
    $script '[ -d .git ]' 'echo \$PWD; git status'

2: Launch a shell when condition matches:
    $script '[ -f .git ]'
    # If no command expression is provided, when condition matches an
    # interactive shell is started. The subshell prompt includes an indicator
    # tail like 'twalk\$ '
    # If the subshell exits with a non-zero result, the recursion is aborted.

EOF
}

MaxDepth=99999
IncludeHiddenDirs=false
Quiet=false
RootDir="$(readlink -f .)"
RootDirEnd=$(( ${#RootDir} + 2 ))

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


do_walk_tree() {
    local depth=$1
    (( depth > MaxDepth )) && \
        return
    local expr="$2"
    local comd="$3"
    local hiddenOpt
    $IncludeHiddenDirs \
        && hiddenOpt=a
    cands=( $(ls -${hiddenOpt}F | grep '/' | grep -vE '(\./|\.\./)' | tr -d '/' ) )
    local nextDepth=$(( ++depth ))
    for dd in "${cands[@]}"; do
        [[ -d "$dd" ]] || continue
        (
            builtin cd -- "$dd"
            relative_path=$(readlink -f .)
            eval "$expr" && {
                $Quiet || {
                    builtin printf ">> ${script} expr true (-q to silence this):\n"
                    builtin printf ">>   root:   %s\n" "$RootDir"
                    builtin printf ">>   subdir: %s\n" "$(readlink -f . | cut -c ${RootDirEnd}-)"
                    builtin printf ">>   expr: |>%s<|\n" "$expr"
                    builtin printf ">>   comd: |>%s<|\n" "$comd"
                } >&2
                eval "$comd" || die "Command failed [$comd] in $PWD"
            }
            do_walk_tree $nextDepth "$expr" "$comd" || die "die at depth=$nextDepth"
        ) || exit 1
    done
}

main() {
    [[ $# -eq 0 ]] && { do_help; exit 1; }
    local filename  # Declare arguments to be parsed as local
    local expr
    local default_comd="Ps1Tail=twalk\$ bash"
    local comd=
    while [[ -n $1 ]]; do
        case $1 in
            -h|--help)
                do_help $*; exit 1 ;;
            -a|--hidden)
                IncludeHiddenDirs=true;;
            -q|--quiet)
                Quiet=true ;;
            -d|--max-depth)
                MaxDepth=$2; shift ;;
            *)
                if [[ -z "$expr" ]]; then
                    expr="$1"
                elif [[ -z "$comd" ]]; then
                    comd="$1"
                else
                    die "Extra unknown argument: [$1]"
                fi
        esac
        shift
    done
    [[ -n "$expr" ]]  || {
        do_help;
        die "No expression provided";
    }
    [[ -n "$comd" ]] || {
        comd="$default_comd"
    }
    do_walk_tree 1 "$expr" "$comd"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
