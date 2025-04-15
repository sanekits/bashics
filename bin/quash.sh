#!/bin/bash
# quash.sh



{
    _qDie() {
        # die has special behavior because we allow disabling 'exit'
        builtin echo "ERROR($(basename "${_qScriptName}")): $*" >&2
        $QNO_EXIT && builtin return 1
        builtin exit 1
    }
    _qUsage() {
        echo "Usage: quash [options] [command]"
        echo "Options:"
        echo "  --tty|-t <path>       Specify trace output terminal (e.g., /dev/pts/2)"
        echo "  -p <N>                Shortcut for --tty /dev/pts/<N>"
        echo "  --notty|-n            Use current terminal for trace output"
        echo "  --findtty|-f          Find available terminals for trace output"
        echo "  --loadrc|-l           Load ~/.bashrc before executing command"
        echo "  --clear|-e            Clear the trace output terminal"
        echo "  --completions|-c <on|off> Enable/disable tab completions"
        echo "  --noexit              Disable 'exit' to preserve the shell"
        echo "  --ps1_disable|-d      Disable PS1 hook functions"
        echo "  --ps4 <color|plain|off> Set PS4 debug prompt style"
        echo "  --                    End of options, pass remaining args as command"
        echo "Docs: https://bit.ly/3G4n8LH"
    }

    _qUsageDie() {
        _qUsage
        echo
        die "$@"
        return
    }
    _qFindTraceTtyCandidates() {
        local myTty; myTty=$(tty)

        #shellcheck disable=SC2009
        mapfile -t TRACE_CANDIDATE_TTYS < <( ps a | grep bash | grep -E ' [SsR]+\+ ' | awk '{print "/dev/" $2}' | sort -u | grep -v "$myTty" )  
    }
    _qBroadcastTtyIdentifiers() {
        # 1. Use 'ps' to list running instances of bash
        # 2. Get list of unique tty's for those instances
        # 3. Filter out our own tty, and those not writable by us,
        # 4. Print an ident banner to each

        for cand in "${TRACE_CANDIDATE_TTYS[@]}"; do
            echo "💥 Quash TTY: $cand 💥" > "${cand}"
        done
    }

    _qFindTraceTty() {
        _qFindTraceTtyCandidates
        _qBroadcastTtyIdentifiers
        if [[ ${#TRACE_CANDIDATE_TTYS[@]} -eq 0 ]]; then
            echo "Can't find any other terminal(s) for trace output.  Open an "
            echo "   additional terminal to use external tracing"
        else
            echo "I found these terminals for trace output: "
            printf "    %s\n" "${TRACE_CANDIDATE_TTYS[@]}"
            echo "Please add \"-t [path]\" or \"-p [N]\" to "
            echo "select the trace output terminal."
            echo
        fi
        echo "To stay with current tty, use --notty|-n"
    }


    _qLaunchInnerCmd() {
        echo
        {
            echo
            echo -e "   Quash is launching: \033[;31m[$*]\033[;0m"
            echo -e "   Start: \033[;31m$(date -Iseconds)\033[;0m"
            echo -e "   PWD: \033[;31m${PWD}\033[;0m"
            echo -e "   Our PID: \033[;31m$$\033[;0m"
            $qRCLOAD && echo -e '   Load ~/.bashrc:' "\033[;31mYES\033[;0m"
            echo -e "   Trace output: \033[;31m$TRACE_PTY\033[;0m"
            echo -e "   _QUASH_BIN: \033[;31m$_QUASH_BIN\033[;0m"
            echo
        } | sed 's,^, ✨ ✨ ✨,' > "${TRACE_PTY}"

        #shellcheck disable=1091
        $qRCLOAD && [[ -f ${HOME}/.bashrc ]] && source "${HOME}/.bashrc"
        #shellcheck disable=2154,2089
        PS4='\033[0;33m$( _0=$?;set +e;exec 2>/dev/null;realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} \033[0;35m^$_0\033[32m ${FUNCNAME[0]:-?}()=>" )\033[;0m '
        #shellcheck disable=2090
        eval "$*"
    }
}

_qMain() {
    _qArgParse()  {
        while [[ -n "$1" ]]; do
            # Here we'll parse and shift anything that belongs to us.  Remaning 
            # args are interpreted as an inner command
            case "$1" in
                --tty|-t)   shift;
                            TRACE_PTY="$1"
                            [[ -e "${TRACE_PTY}" ]] || {
                                touch "${TRACE_PTY}" || {  # The arg might be a file to be created?
                                    _qDie "--tty $1 -- device not found"
                                    return
                                }
                            }
                            shift
                            ;;
                -p)         shift; # Shortcut for --tty <path> is to just specify the pts number with -p NN
                            TRACE_PTY="/dev/pts/$1"
                            [[ -e "${TRACE_PTY}" ]] || { _qDie "-p $1 -- device /dev/pts/$1 not found"; return ; }
                            shift
                            ;;
                --notty|-n ) shift; TRACE_PTY=$(tty) 
                            ;;
                --findtty|-f) shift; _qFindTraceTty; return
                            ;;
                --help|-h) shift; _qUsage "$@"; return
                            ;;
                --clear|-e) shift; printf "\033c" >"${TRACE_PTY}" 
                            ;;
                --loadrc|-l) shift; qRCLOAD=true 
                            ;;
                --completions|-c) shift; 
                            case $1 in
                                1|on|yes) bind '"\t":complete' ;;
                                0|off|no) bind -r "\t";;
                                *) echo "Unknown or missing arg to -c: $1" >&2;;
                            esac
                            shift
                            ;;
                --noexit) shift;
                            # Disable 'exit' to preserve our shell
                            export QNO_EXIT=true
                            exit() {
                                #shellcheck disable=2317
                                echo "$?:$*: --noexit mode, use 'builtin exit' if you're serious, 'unset exit to return to normal'" >&2
                            }
                            trap 'echo "$?: --noexit failed, and here we are.  Sorry for your loss."; read -rn 1' exit
                            echo "noexit mode enabled, use 'builtin exit' if you're serious, 'unset exit' to return to normal." >&2
                            ;;
                --ps1_disable|-d) shift;
                            # Turn off PS1 hook functions to reduce noise
                            unset __pcwrap_run __pcwrap_items PROMPT_COMMAND
                            ;;
                --ps4)      shift; 
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
                            shift
                            ;;
                --)         shift; break ;;
                *)          break ;;
            esac
        done
        _qTAIL_ARGS=( "$@" )
    } # end _qArgParse()

    _qScriptName="${_qScriptName:-$(readlink -f "$0")}"

    _QUASH_BIN=${_QUASH_BIN:-"${HOME}/.local/bin/bashics"}

    TRACE_PTY=${TRACE_PTY:-} #  Path to trace pty, e.g. /dev/pts/2

    qRCLOAD=${qRCLOAD:-false}  # --loadrc|-l: read ~/.bashrc before command execution
    QNO_EXIT=false # --noexit turns this on

    set -o pipefail
    _qArgParse "$@"

    if [[ -n "$TRACE_PTY" ]]; then
        exec 9>&- 
        exec 9> "${TRACE_PTY}"
        BASH_XTRACEFD=9
        export BASH_XTRACEFD
        echo "Trace output assigned to $TRACE_PTY, use -x|+x to control trace output" >"${TRACE_PTY}"
    else
        _qFindTraceTty 
    fi
    if [[ ${#_qTAIL_ARGS} -gt 0 ]]; then
        _qLaunchInnerCmd "${_qTAIL_ARGS[@]}"
    fi
}

[[ -z ${_qSourceMe} ]] && {
    _qMain "$@"
}
