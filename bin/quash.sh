#!/bin/bash
# quash.sh

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

TRACE_HANDLE=9  # Arbitrarily chosen file handle for tracing.
TRACE_PTY= #  Path to trace pty, e.g. /dev/pts/2

TRACE_CANDIDATE_TTYS=()
SOURCE_MODE=false #  -s|--source: read commands in gulp from stdin, no child process created.
REPL_MODE=false   #  -r|--repl:  read commands one-at-a-time from stdin, eval interactively
qRCLOAD=false  # --loadrc|-l: read ~/.bashrc before command input (SOURCE or REPL only)

set -o pipefail

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

_qUsage() {
    cat <<-EOF
Quash 0.6.1 -- shell script trace wrapper.

Usage:
    quash.sh <--tty|-t /path/to/tty> <-p [N]> <-r|--repl> <-s|--source> [--] <script-name> [script args]

Required:

    --tty|-t /path/to-tty:  Send trace output to this terminal/pipe/file

  Or:

    -p:  Output pty short form e.g. '-p 1' is like '--tty /dev/pts/1'

    When run without --tty or -p, we print the tty paths to all found terminals.

Options:
    --:  End of quash arguments (remaining args are unparsed, passed to <script-name>)
    --repl|-r: REPL mode: read and eval one line at a time from stdin
    --source|-s: SOURCE mode: <script-name> will be sourced without starting child proc.
    --loadrc|-l: read ~/.bashrc before command input. (REPL or SOURCE mode only)
    <script-name>: path to script to be executed/evaluated.
    [script args]: Additional arguments forwarded to script or REPL env.

EOF
}

usageDie() {
    _qUsage
    echo
    die "$@"
}

FindTraceTtyCandidates() {
    local myTty=$(tty)

    TRACE_CANDIDATE_TTYS=( $( ps a | grep bash | grep -E ' [SsR]+\+ ' | awk '{print "/dev/" $2}' | sort -u | grep -v "$myTty" )  )
}

BroadcastTtyIdentifiers() {
    # 1. Use 'ps' to list running instances of bash
    # 2. Get list of unique tty's for those instances
    # 3. Filter out our own tty, and those not writable by us,
    # 4. Print an ident banner to each

    for cand in "${TRACE_CANDIDATE_TTYS[@]}"; do
        echo "💥 Quash TTY: $cand 💥" > "${cand}"
    done
}

_qREPL() {
    declare -i __quash_lastresult
    #echo -n "Call stack: " >&9
    #echo "${FUNCNAME[*]}" | tr ' ' '\n' | tac | xargs >&9
    set -o vi
    set -o history
    shopt -s histverify
    HISTFILE=~/.bash_history
    history -r

    while read -p "Quash>" -e __quash_inpline; do
        eval "set -x; $__quash_inpline"
        __quash_lastresult=$?; set +x
        history -s "$__quash_inpline"
    done
}

_qSOURCE() {
    declare -i __quash_lastresult
    set -x; source "$@"
    __quash_lastresult=$?
    set +x
}

LaunchDebugee() {
    echo
    {
        echo
        echo -e "   Quash is launching: \033[;31m$1\033[;0m"
        echo -e "   Start: \033[;31m$(date -Iseconds)\033[;0m"
        echo -e "   PWD: \033[;31m${PWD}\033[;0m"
        if ${SOURCE_MODE}; then
            echo -e "   Source: \033[;31mstdin\033[;0m"
        elif ${REPL_MODE}; then
                echo -e "   Source: \033[;31mstdin (REPL)\033[;0m"
        else
            echo -e "   Source: \033[;31m<file arg \$0>\033[;0m"
        fi
        $qRCLOAD && echo -e '   Load ~/.bashrc:' "\033[;31mYES\033[;0m"
        echo -e "   Trace output: \033[;31m$TRACE_PTY\033[;0m"
        echo -e "   Command line: [\033[;31m" "$@" "\033[;0m]"
        echo
    } | sed 's,^, ✨ ✨ ✨,' > ${TRACE_PTY}

    PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[;32m ${FUNCNAME[0]}() ${#FUNCNAME[@]}:\033[;0m✨ '
    export PS4
    exec 9> ${TRACE_PTY}
    BASH_XTRACEFD=9
    export BASH_XTRACEFD
    if ${SOURCE_MODE}; then
        _qSOURCE "$@"
    elif ${REPL_MODE}; then
        _qREPL "$@"
    else
        exec bash -x "$@"
    fi
}


[[ -z ${sourceMe} ]] && {
    FWD_ARGS=()
    while [[ -n "$1" ]]; do
        case "$1" in
            --tty|-t)   shift;
                        TRACE_PTY="$1"
                        [[ -e "${TRACE_PTY}" ]] || {
                            touch "${TRACE_PTY}" || {  # The arg might be a file to be created?
                                die "--tty $1 -- device not found"
                            }
                        }
                        ;;

            --help|-h) _qUsage "$@"; exit 1;;

            --source|-s) SOURCE_MODE=true ;
                        ;;

            --loadrc|-l) qRCLOAD=true ;
                        ;;

            --repl|-r) REPL_MODE=true ;
                        ;;

            -p)         shift;
                        TRACE_PTY="/dev/pts/$1"
                        [[ -e "${TRACE_PTY}" ]] || die "-p $1 -- device /dev/pts/$1 not found"
                        ;;

            --)         shift;
                        FWD_ARGS+=( "$@" );
                        break
                        ;;

            *) FWD_ARGS+=("$1") ;;
        esac
        shift
    done

    [[ -z "${TRACE_PTY}" ]] && {
        FindTraceTtyCandidates

        BroadcastTtyIdentifiers
        if [[ ${#TRACE_CANDIDATE_TTYS[@]} -eq 0 ]]; then
            echo "Can't find any other terminal(s) for trace output.  Open an "
            echo "   additional bash shell in its own terminal."
        else
            echo "I found these terminals for trace output: "
            printf "    %s\n" "${TRACE_CANDIDATE_TTYS[@]}"
            echo "Please add \"-t [path]\" or \"-p [N]\" before the name of your script to "
            echo "select the trace output terminal, e.g.:"
            echo
            [[ ${#FWD_ARGS[@]} -eq 0 ]] && {
                echo "   quash.sh --tty /dev/pts/1 ./my-script.sh --foo "
            } || {
                echo "   quash.sh --tty /dev/pts/1 ${FWD_ARGS[@]}"
            }
            echo "Use --help for options."
        fi
        exit 1
    } >&2

    if ! [[ ${SOURCE_MODE} || ${REPL_MODE} ]]; then
        [[ ${#FWD_ARGS[@]} -eq 0 ]] && {
            usageDie "No script path provided"
            exit 2
        }
    fi
    LaunchDebugee "${FWD_ARGS[@]}"
}

