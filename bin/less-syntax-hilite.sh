#!/bin/bash
# less-syntax-hilite.sh
#  Invokes `less` after piping through the Python pygments `pygmentize` command: i.e. show
# the content with color syntax highlighting.

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}


[[ -z ${sourceMe} ]] && {
    which less &>/dev/null || {
        die "Command 'less' not found on the PATH.  Try '(sudo) apt-get install less' to resolve the dependency."
    }
    which pygmentize &>/dev/null || {
        die "Command 'pygmentize' not found on the PATH.  Try \"$(get_py_version) -m pip install pygments\" to resolve the dependency."
    }
    Less=$(which less)
    Pygmentize=$(which pygmentize)
    export LESS=" -R"
    export LESSOPEN="| $Pygmentize %s"
    $Less "$@"

    builtin exit
}
command true
