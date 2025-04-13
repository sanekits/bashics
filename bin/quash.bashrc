#!/bin/bash
# quash.bashrc
# Loaded at shell init time usually.  Define the current-shell elements
# for quash support

_QUASH_BIN=${_QUASH_BIN:-"${HOME}/.local/bin/bashics"}

quash() {
    #shellcheck disable=1091
    source "${HOME}/.local/bin/bashics/quash.sh" "$@"
}

