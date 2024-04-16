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

usageDie() {
    cat <<-EOF
Quash 0.4 -- shell script trace wrapper.

Usage: quash.sh --tty|-t /path/to/tty [--] <script-name> [script args]
    --tty|-t /path/to-tty:  Send trace output to this terminal
    --:  End of quash arguments (remaining args are passed to <script-name>)

  When executed without --tty, we print the tty paths to all found terminals.
EOF
    echo -n '  ' ; die "$@"
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
    {
        echo
        echo
        echo -e " -- $scriptName is launching \033[;31m$1\033[;0m:"
        echo "   Start: $(date -Iseconds)"
        echo "   PWD: $PWD"
        echo "   Trace output: $TRACE_PTY"
        echo -e "   Command line: [\033[;31m" "$@" "\033[;0m]"
    } | sed 's,^, ✨ ✨ ✨,' > ${TRACE_PTY}

    PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    export PS4
    exec 9> ${TRACE_PTY}
    BASH_XTRACEFD=9
    export BASH_XTRACEFD
    exec /bin/bash -x "$@"
}


[[ -z ${sourceMe} ]] && {
    FWD_ARGS=()
    while [[ -n "$1" ]]; do
        case "$1" in
            --tty|-t) shift;
                      TRACE_PTY="$1"
                      [[ -e "${TRACE_PTY}" ]] || die "--tty $1 -- device not found"
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
            echo "Can't find any other terminal(s) for trace output.  Open an additional bash shell in its own terminal."
        else
            echo "I found these terminals for trace output: "
            printf "    %s\n" "${TRACE_CANDIDATE_TTYS[@]}"
            echo "Please add \"--tty [path]\" before the name of your script to select the trace output terminal, e.g.:"
            [[ ${#FWD_ARGS[@]} -eq 0 ]] && {
                echo "   quash.sh --tty /dev/pts/NN <script-name> [args]"
            } || {
                echo "   quash.sh --tty /dev/pts/NN ${FWD_ARGS[@]}"
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

