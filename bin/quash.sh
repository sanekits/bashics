#!/bin/bash
# quash.sh
# To understand quash, you have to consider that quash.bashrc injects a launcher
# function named 'quash()' which takes one of 2 paths: if we're already in a
# quashified shell, we will source quash.sh and pass in $@ -- such commands
# will be quashified without necessarily starting a new shell.  
#
# But if the outer quash() call detects a plain shell, it will launch
# another bash instance and inject quash into it, then the $@ args will
# be passed to bash in that context.
#
# So when reading this code, a key question is "is _QNEW true?"  If so, then
# we are executing in the outermost quashified shell. 

export _QUASH_VERSION=1.0.2
#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '
if ${_QNEW:-false}; then
    # mark the top so we know when we're here
    export _QUASH_TOPLVL=${SHLVL}
    unset _QNEW
    (
        _qSourceMe=1 QUASH_PTY=/dev/stderr source ${_QUASH_BIN}/quash.sh 
        bash
    )
    exit
fi


{
    exit() {
        if (( (_QUASH_TOPLVL-1) <= SHLVL )); then
            echo "This is top-level (${SHLVL}). Can't do normal 'exit' here . Try 'builtin exit' if you're serious."
            return 1
        else
            builtin exit
        fi
    }
    _qDie() {
        # die has special behavior because we allow disabling 'exit'
        builtin echo "ERROR($(basename "${_qScriptName}")): $*" >&2
        exit 1
    }
    _qErr() {
        ( _qDie "$@" )
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
        echo "  -x                    Wrap command execution with -x;cmd;-x"
        echo "  -ex                   Wrap command execution with clear;-x;cmd;-x"
        echo "  --completions|-c <on|off> Enable/disable tab completions"
        echo "  --noexit              Disable 'exit' to preserve the shell"
        echo "  --ps1_disable|-d      Disable PS1 hook functions"
        echo "  --ps4 <color|plain|off> Set PS4 debug prompt style"
        echo "  -v|--version          Print quash version info"
        echo "  --                    End of options, pass remaining args as command"
        echo "Docs: https://bit.ly/3G4n8LH"
    }
    parse_ps1_tail() {
        if (( $SHLVL ==_QUASH_TOPLVL )); then
            export Ps1Tail="🎲${SHLVL}"
        else
            export Ps1Tail="🍅${SHLVL}"
        fi
        echo "$Ps1Tail"
    }

    _qInnerBashrc() {
        # Invoked as --rcfile for inner bash() replacement
        cat $HOME/.bashrc
        echo sourceMe=1
        cat "${_QUASH_BIN}/quash.sh"
        unset sourceMe
        alias q=quash
    }
    bash() {
        command bash --rcfile <(_qInnerBashrc) "$@"
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


    _qStatus() {
        echo -e "   PWD: \033[;31m${PWD}\033[;0m"
        echo -e "   Our PID: \033[;31m$$\033[;0m"
        $qRCLOAD && echo -e '   Load ~/.bashrc:' "\033[;31mYES\033[;0m"
        echo -e "   QTRACE_PTY: \033[;31m${QTRACE_PTY:-/dev/stderr}\033[;0m"
        echo -e "   _QUASH_BIN: \033[;31m${_QUASH_BIN:-}\033[;0m"
        echo -e "   SHLVL: \033[;31m$SHLVL\033[;0m"
        echo -e "   _QUASH_TOPLVL: \033[;31m${_QUASH_TOPLVL:-}\033[;0m"
    }
    _qLaunchInnerCmd() {
        set +u
        echo
        {
            _qStatus
            echo -e "   Quash is launching: \033[;31m[$*]\033[;0m"
            echo -e "   Start: \033[;31m$(date -Iseconds)\033[;0m"
            echo
        } | sed 's,^, ✨ ✨ ✨,' > "${QTRACE_PTY:-/dev/stderr}"
        set -u

        #shellcheck disable=1091
        $qRCLOAD && [[ -f ${HOME}/.bashrc ]] && source "${HOME}/.bashrc"
        #shellcheck disable=2154,2089
        PS4='\033[0;33m$( _0=$?;set +e;exec 2>/dev/null;realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} \033[0;35m^$_0\033[32m ${FUNCNAME[0]:-?}()=>" )\033[;0m '
        $TRACE_WRAP_CLEAR_COMMAND && printf "\033c" >& ${QTRACE_PTY:-/dev/stderr}
        if $TRACE_WRAP_COMMAND || $TRACE_WRAP_CLEAR_COMMAND; then set -x; fi
        if $EVAL_WRAP_SUBSHELL; then
            ( eval "$*" )
        else
            eval "$*"
        fi
        if $TRACE_WRAP_CLEAR_COMMAND ||$TRACE_WRAP_COMMAND; then set +x; fi

    }
    _qArgParse()  {
        while [[ -n "$1" ]]; do
            # Here we'll parse and shift anything that belongs to us.  Remaning 
            # args are interpreted as an inner command
            case "$1" in
                -s|--status) shift; _qStatus; return ;;
                --tty|-t)   shift;
                            [[ -e $1 ]] || { _qErr "-tty \"$1\" bad device/filename";  return; }
                            if [[ "$1" != ${QTRACE_PTY:-} ]]; then
                                exec 9>&-
                            fi
                            QTRACE_PTY="$1"
                            shift
                            ;;
                -p)         shift; # Shortcut for --tty <path> is to just specify the pts number with -p NN
                            [[ $1 =~ [0-9]+ ]] || { _qErr "-p $1 -- expected a number, try --findtty"; return; }
                            [[ -e /dev/pts/$1 ]] || { _qErr "-p $1 -- device /dev/pts/$1 not found";  return; }
                            QTRACE_PTY="/dev/pts/$1"
                            shift
                            ;;
                -x)         shift; # turn on trace debug just before running the command, and back off after.
                            TRACE_WRAP_COMMAND=true
                            ;;
                -z|--subshell) shift;  EVAL_WRAP_SUBSHELL=true 
                            ;;
                --notty|-n ) shift; QTRACE_PTY=/dev/stderr
                            ;;
                --findtty|-f) shift; _qFindTraceTty; return
                            ;;
                --help|-h) shift; _qUsage "$@"; return
                            ;;
                --clear|-e) shift; printf "\033c" >"${QTRACE_PTY:/dev/stderr}" 
                            ;;
                -ex)        shift; TRACE_WRAP_CLEAR_COMMAND=true
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
                --ps1_disable|-d) shift;
                            # Turn off PS1 hook functions to reduce noise
                            unset __pcwrap_run __pcwrap_items PROMPT_COMMAND
                            PROMPT_COMMAND=parse_ps1_tail
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
                -v|--version) shift; 
                            echo "quash.sh version $_QUASH_VERSION"; false; return ;;
                --)         shift; break ;;
                *)          break ;;
            esac
        done
        _qTAIL_ARGS=( "$@" )
    } # end _qArgParse()
}

_qMain() {
    _qArgParse "$@"
    _qScriptName="${_qScriptName:-$(readlink -f "$0")}"

    export _QUASH_BIN=${_QUASH_BIN:-"${HOME}/.local/bin/bashics"}

    export QTRACE_PTY=${QTRACE_PTY:-/dev/stderr} #  Path to trace pty, e.g. /dev/pts/2
    TRACE_WRAP_COMMAND=false  # --clear|-x means "wrap the command execution with -x; command ;+x
    TRACE_WRAP_CLEAR_COMMAND=false # -ex means "wrap the command execution with "clear screen;-x;command;+x
    EVAL_WRAP_SUBSHELL=false    # -s|--subshell makes the inner eval() call in a subshell (so the command can't force exit, etc.)

    qRCLOAD=${qRCLOAD:-false}  # --loadrc|-l: read ~/.bashrc before command execution
    alias q=quash

    if [[ ${#_QTAIL_ARGS[@]} == 0 ]] ; then
        if ${_QNEW:-false}; then
            _QNEW=false bash
            return
        fi
    fi
    #shellcheck disable=2034

    set -o pipefail
    if [[ -n "${QTRACE_PTY:-}" ]]; then
        local qOldTracePty=$( readlink -f /proc/self/fd/9 2>/dev/null || : )
        if [[ "${QTRACE_PTY}" != "$qOldTracePty" ]]; then
            exec 9>&-
            exec 9> "${QTRACE_PTY}"
            BASH_XTRACEFD=9
            echo "Trace output assigned to $QTRACE_PTY, use -x|+x to control trace output" >"${QTRACE_PTY:-/dev/stderr}" 
        fi
    else
        _qFindTraceTty 
    fi
    
    if [[ ${#_qTAIL_ARGS[@]} -gt 0 ]]; then
        _qLaunchInnerCmd "${_qTAIL_ARGS[@]}"
    fi
}

_QTAIL_ARGS=()

[[ -z ${_qSourceMe:-} ]] && {
    _qMain "$@"
}
