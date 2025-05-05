# For quash debugging.  Probably not a commit candidate

case $1 in
    set_x)
        # e.g.: set_x /dev/pts/??
        shift
        if [[ -e $1 ]]; then
            export QTRACE_PTY=$1
            export qOldTracePty=$QTRACE_PTY
            exec 9>&-
            exec 9>$1
            BASH_XTRACEFD=9
            echo "trace set to $1" >&9
        fi
        ;;
    *) 
        # No args path:
        export _QUASH_BIN=/workarea/bin
        source /jumpstart.bashrc; 
        vi_mode_on noexec; 
        cd /workarea/bin; 
        alias exit=no; 

        alias ref='source /workarea/bin/tmp-init.bashrc'

        case $SHLVL in
            1) alias exit=no; ;;
            *) ;;
        esac
        {
            tty
            echo level-$SHLVL
            echo _QUASH_TOPLVL=${_QUASH_TOPLVL:-}
            echo "_QUASH_BIN=${_QUASH_BIN}"
            echo "fd9: $(ls -al /proc/self/fd/9 2>/dev/null || :)"
            echo -n "quash() defined: "
                declare -f quash &>/dev/null && echo YES || echo NO
        } >&2
    ;;
esac
