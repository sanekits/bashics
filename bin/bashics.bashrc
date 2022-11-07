# bashics.bashrc - shell init file for bashics sourced from ~/.bashrc

bashics-semaphore() {
    [[ 1 -eq  1 ]]
}

#  DIAGNOSTIC HELPERS
###########################################################

die() {
    echo "ERROR: $*" >&2
    exit 1
}

stub() {
    # Print debug output to stderr.  Recommended call snippet:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    [[ -n $NoStubs ]] && return
    [[ -n $StubCount ]] || StubCount=1
    {
        builtin printf "  <<< STUB($StubCount) "
        builtin printf "[%s] " "$@"
        builtin printf " >>> "
        (( StubCount++ ))
    } >&2
}

# set_bashdebug_mode is a function that's useful for debugging shell commands+script in general:
[[ -f ~/.local/bin/bashics/set_bashdebug_mode ]] && source ~/.local/bin/bashics/set_bashdebug_mode


##  Fixing Dumb Defauts
######################################################

IGNOREEOF="3"   # Don't close interactive shell for ^D

TERM=xterm-256color

[[ -n ${BASH_VERSION[@]} ]] {
    # check the window size after each command and, if necessary,
    # update the values of LINES and COLUMNS.
    shopt -s checkwinsize

    # Magic space expands !! and !-{n} when you hit spacebar after.  You can also do
    # {cmd-frag}!<space> to expand the last command that started with that frag.
    bind Space:magic-space

    shopt -s direxpand 2>/dev/null || true
fi

function reset {
    # The standard reset doesn't restore the cursor, necessarily.
    setterm -cursor on
    command reset
}

# disable flow control for terminal:
/bin/stty -ixon -ixoff 2>/dev/null

[[ -n $EDITOR ]] || export EDITOR=vi



##  Command improvements
#######################################################

function initLsStuff {

    function ls_less {
        command ls --color=yes -- "$@" | less -RFSX
    }
    function ls_grep() {
        command ls -la | command grep -E "$@"
        builtin set +f
    }

    alias lsl=ls_less
    alias ll='ls -alF'
    alias la='ls -A'
    alias lra='ls -lrta'
    alias l='ls -CF'
    alias l1='ls -1'
    alias lr='ls -lrt'
    alias lg='builtin set -f; ls_grep'
    alias lsg='builtin set -f; ls_grep'

	if $MACOSX; then   # Mac doesn't have dircolors
		CLICOLOR=YES
		alias ls='ls -G'
	elif which dircolors &>/dev/null; then
		eval $(dircolors --bourne-shell)
		alias ls='command ls --color=auto '
        LS_COLORS+=':ow=01;33' # fix horrid unreadable blue-on-green other-writable dirnames
	fi
}


initLsStuff

[[ 1 -eq 1  ]] # END
