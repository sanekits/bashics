#!/bin/bash
# completion-debug.sh

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

advise_missing_bash_completion() {
    cat <<-XEOF
    The bash-completion package does not seem to be installed.  You might be able
    to solve this with:

      sudo apt-get update -y && apt-get install bash-completion

    This package provides essential basic functionality for autocompletion in bash.

XEOF
}

advise_missing_bashics_semaphore() {
    cat <<-XEOF
    The function "bashics-semaphore()" was not found in your shell environment.  This
    is normally initialized when ~/.local/bin/bashics/bashics.bashrc is sourced during
    shell startup.  You should trace the logic of your ~/.bashrc.
XEOF
}

advise_missing_make() {
    cat <<-XEOF
    The 'make' program was not found on your PATH.  This is a basic Unix tool which is
    bundled with most distributions by default.   There may be something missing from
    your PATH, or perhaps you need to add make to your installation, e.g. this might
    work:

       sudo apt-get install make

XEOF
}

advise_missing_make_completion_spec() {
    cat <<-XEOF
    A probe with 'complete -p make' failed.  This means that autocompletion for
    'make' is not working.
XEOF
}

check_bash_completion_dpkg() {
    which dpkg &>/dev/null || die "Can't find dpkg command on the PATH"
    dpkg -s bash-completion &>/dev/null || {
        advise_missing_bash_completion
        false
        return
    }
    echo "bash-completion installed: Ok"
}

check_bashics_init() {
    bash -ic '[[ $(type -t bashics-semaphore) == function ]]' || {
        advise_missing_bashics_semaphore
        false
        return
    }
    echo "bashics-semaphore init: Ok"
}

check_make() {
    which make &>/dev/null || {
        advise_missing_make
        false
        return
    }
    bash -ic 'complete -p make &>/dev/null' || {
        advise_missing_make_completion_spec
        false
        return
    }

    echo "make checked: Ok"
}


[[ -z ${sourceMe} ]] && {
    check_bash_completion_dpkg || exit 19
    check_bashics_init || exit 21
    check_make || exit 23
    echo "Bash completion setup checks completed: Ok"
    builtin exit
}
command true
