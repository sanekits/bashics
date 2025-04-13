#!/bin/bash
# quash.sh

scriptName="$(readlink -f "$0")"

_QUASH_BIN=${_QUASH_BIN:-"${HOME}/.local/bin/bashics"}

TRACE_PTY= #  Path to trace pty, e.g. /dev/pts/2

TRACE_CANDIDATE_TTYS=()
SOURCE_MODE=false #  -s|--source: read commands in gulp from stdin, no child process created.
REPL_MODE=false   #  -r|--repl:  read commands one-at-a-time from stdin, eval interactively
qRCLOAD=false  # --loadrc|-l: read ~/.bashrc before command input (SOURCE or REPL only)
QNO_EXIT=false # --noexit turns this on

set -o pipefail

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    $QNO_EXIT && builtin return 1
    builtin exit 1
}

_qUsage() {
    cat "${_QUASH_BIN}/quash.md"
}

usageDie() {
    _qUsage
    echo
    die "$@"
}

FindTraceTtyCandidates() {
    local myTty; myTty=$(tty)

    #shellcheck disable=SC2009
    mapfile -t TRACE_CANDIDATE_TTYS < <( ps a | grep bash | grep -E ' [SsR]+\+ ' | awk '{print "/dev/" $2}' | sort -u | grep -v "$myTty" )  
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

    while read -rp "Quash>" -e __quash_inpline; do
        eval "set -x; $__quash_inpline"
        __quash_lastresult=$?; set +x
        history -s "$__quash_inpline"
    done
}

_qSOURCE() {
    declare -i __quash_lastresult
    set -x; 
    #shellcheck disable=SC1090
    source "$*"
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
        echo -e "   _QUASH_BIN: \033[;31m$_QUASH_BIN\033[;0m"
        echo -e "   Command line: [\033[;31m" "$@" "\033[;0m]"
        echo
    } | sed 's,^, ✨ ✨ ✨,' > "${TRACE_PTY}"

    #shellcheck disable=2154,2089
    PS4='\033[0;33m$( _0=$?;set +e;exec 2>/dev/null;realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} \033[0;35m^$_0\033[32m ${FUNCNAME[0]:-?}()=>" )\033[;0m '
    #shellcheck disable=2090
    export PS4
    exec 9> "${TRACE_PTY}"
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

_qMain() {
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

            --help|-h) _qUsage "$@"; return;;

            --source|-s) SOURCE_MODE=true ; return ;;

            --loadrc|-l) qRCLOAD=true ;
                        ;;

            --noexit) # Disable 'exit' to preserve our shell
                    export QNO_EXIT=true
                    exit() {
                        echo "--noexit mode, use 'builtin exit' if you're serious" >&2
                    }
                    trap 'echo "--noexit failed, and here we are.  Sorry."' exit
                    echo "--noexit mode enabled, use 'builtin exit' if you're serious" >&2
                    return
                    ;;

            --repl|-r) REPL_MODE=true ;
                        ;;

            --ps4) shift; 
                        case $1 in
                            color) 
                                #shellcheck disable=2154
                                PS4='\033[0;33m$( _0=$?;set +e;exec 2>/dev/null;realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} \033[0;35m^$_0\033[32m ${FUNCNAME[0]:-?}()=>" )\033[;0m '
                            ;;
                            plain) 
                                #shellcheck disable=2154
                                PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '
                            ;;
                            off) unset PS4;;
                            *) echo "Bad --ps4 arg: try color|plain|off" >^&2; false; return ;;
                        esac
                        return
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
            if [[ ${#FWD_ARGS[@]} -eq 0 ]]; then
                echo "   quash.sh --tty /dev/pts/1 ./my-script.sh --foo "
            else
                echo "   quash.sh --tty /dev/pts/1 ${FWD_ARGS[*]}"
            fi
            echo "Use --help for options."
        fi
        true; return
    } >&2

    if ! [[ ${SOURCE_MODE} || ${REPL_MODE} ]]; then
        [[ ${#FWD_ARGS[@]} -eq 0 ]] && {
            usageDie "No script path provided"
        }
    fi
    LaunchDebugee "${FWD_ARGS[@]}"
}

[[ -z ${_qSourceMe} ]] && {
    _qMain "$@"
}
