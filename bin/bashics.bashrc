# bashics.bashrc - shell init file for bashics sourced from ~/.bashrc

bashics-semaphore() {
    [[ 1 -eq  1 ]]
}

# Adding to the PATH, distinct.  Use $2=after to append instead of prefix:
__pathmunge__ () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}

#  DIAGNOSTIC HELPERS:
###########################################################

die() {
    echo "ERROR: $*" >&2
    exit 1
}

set_ps4_color() {
    PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
}

set_ps4_plain() {
    PS4='+$?(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
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
[[ -f ~/.local/bin/bashics/set_bashdebug_mode ]] \
    && source ~/.local/bin/bashics/set_bashdebug_mode


# complete_alias is it's own whole thing (https://github.com/sanekits/complete-alias)
[[ -f ~/.local/bin/bashics/completion_loader ]] && {
    source ~/.local/bin/bashics/completion_loader
}

# vi-mode.sh has an 'on' option which sets up a symlink to enable
# vi command line editing
[[ -f ~/.inputrc ]] && {
    [[ $(readlink -f ~/.inputrc 2>/dev/null) == *inputrc-vi-on ]] && {
        set -o vi
    }
}


##  Fixing Dumb Defauts:
######################################################

IGNOREEOF="3"   # Don't close interactive shell for ^D

TERM=xterm-256color

set +o noclobber  # We don't need Mom telling us about overwriting files

[[ -n ${BASH_VERSION[@]} ]] && {
    # check the window size after each command and, if necessary,
    # update the values of LINES and COLUMNS.
    shopt -s checkwinsize

    # Magic space expands !! and !-{n} when you hit spacebar after.  You can also do
    # {cmd-frag}!<space> to expand the last command that started with that frag.
    # (The conditional ensures that line editing is enabled before we turn on magic-space)
    [[ :$SHELLOPTS: =~ :(vi|emacs): ]] && bind Space:magic-space

    shopt -s direxpand 2>/dev/null || true
}

function reset {
    # The standard reset doesn't restore the cursor, necessarily.
    setterm -cursor on
    command reset
}

# disable flow control for terminal:
/bin/stty -ixon -ixoff 2>/dev/null

[[ -n $EDITOR ]] \
    || export EDITOR=vi


uname -a | grep -E MINGW &>/dev/null && {
    # On git-bash, it is possible to make symlinks work but
    # you have to jump through hoops, see:
    #  https://gist.github.com/Stabledog/594fd0f3c6c23ac9619d33a9f1d94cec
    export MSYS=winsymlinks:native  # git bash
}


##  Command improvements:
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
    alias ls='command ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias lra='ls -lrta'
    alias l='ls -CF'
    alias lr='ls -lrt'
    alias lg='builtin set -f; ls_grep'
    alias lsg='builtin set -f; ls_grep'

	[[ -n $MACOSX ]] || MACOSX=false
	if $MACOSX; then   # Mac doesn't have dircolors
		CLICOLOR=YES
		alias ls='ls -G'
	elif which dircolors &>/dev/null; then
		eval $(dircolors --bourne-shell)
		alias ls='command ls --color=auto '
        LS_COLORS+=':ow=01;33' # fix horrid unreadable blue-on-green other-writable dirnames
	fi
}

define_cdpp_aliases() {
    alias .p='popd &>/dev/null'
    alias .-='builtin cd -'
    alias .1='builtin  cd ..'
    alias .2='builtin pushd ../.. >/dev/null'
    alias .3='builtin pushd ../../.. >/dev/null'
    alias .4='builtin pushd ../../../.. >/dev/null'
    alias .5='builtin pushd ../../../../.. >/dev/null'
    alias .6='builtin pushd ../../../../../.. >/dev/null'
}

function less_syntax_hilite() {
    #Help invoke less using Python pygments as syntax-coloring provider (pip install pygments first)
    less-syntax-hilite.sh "$@"
}


initLsStuff
define_cdpp_aliases

function find-up-tree() {
    find-up-tree.sh "$@"
}

alias fut='find-up-tree.sh'

# We don't like people aliasing `rm` to be "helpful":
unalias rm &>/dev/null

[[ 1 -eq 1  ]] # END
