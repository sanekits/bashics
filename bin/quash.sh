#!/bin/bash
# quash.sh

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

TRACE_HANDLE=9  # Arbitrarily chosen file handle for tracing.
TRACE_PTY= #  Path to trace pty, e.g. /dev/pts/2

TRACE_CANDIDATE_TTYS=()

set -o pipefail

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

usage() {
    cat <<-EOF
Quash 0.5.0 -- shell script trace wrapper.

Usage:
    quash.sh <--tty|-t /path/to/tty> <-p [N]> [--] <script-name> [script args]

Options:
    --tty|-t /path/to-tty:  Send trace output to this terminal/pipe/file
    -p:  Output pty short form (e.g. '-p 1' => '--tty /dev/pts/1')
    --:  End of quash arguments (remaining args are passed to <script-name>)

  When executed without --tty or -p, we print the tty paths to all found terminals.
EOF
}

usageDie() {
    usage
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

LaunchDebugee() {
    echo
    {
        echo
        echo -e "   Quash is launching: \033[;31m$1\033[;0m"
        echo -e "   Start: \033[;31m$(date -Iseconds)\033[;0m"
        echo -e "   PWD: \033[;31m${PWD}\033[;0m"
        echo -e "   Trace output: \033[;31m$TRACE_PTY\033[;0m"
        echo -e "   Command line: [\033[;31m" "$@" "\033[;0m]"
        echo
    } | sed 's,^, ✨ ✨ ✨,' > ${TRACE_PTY}

    PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[;32m ${FUNCNAME[0]}:+${FUNCNAME[0]}() ${#FUNCNAME[@]}:\033[;0m✨ '
    export PS4
    exec 9> ${TRACE_PTY}
    BASH_XTRACEFD=9
    export BASH_XTRACEFD
    exec bash -x "$@"
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
            -p)         shift;
                        TRACE_PTY="/dev/pts/$1"
                        [[ -e "${TRACE_PTY}" ]] || die "-p $1 -- device /dev/pts/$1 not found"
                        ;;
            --) shift; break ;;
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
        fi
        exit 1
    } >&2

    if [[ ${#FWD_ARGS[@]} -eq 0 ]]; then
        usageDie "No script path provided"
        exit 2
    fi
    LaunchDebugee "${FWD_ARGS[@]}"
}

