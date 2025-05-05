#!/bin/bash
# quash.bashrc
# Loaded at shell init time usually.  Define the current-shell elements
# for quash support

export _QUASH_BIN=${_QUASH_BIN:-"${HOME}/.local/bin/bashics"}

quash() {
    _QNEW=false
    if [[ -z ${_QUASH_TOPLVL:-} ]]; then
            #shellcheck disable=1091,2317
            _qSourceMe=1 _QNEW=true source "${_QUASH_BIN}/quash.sh"
            #shellcheck disable=2317
    else
        #shellcheck disable=1091
        source "${_QUASH_BIN}/quash.sh" "$@"
    fi
    unset _QNEW
    alias q=quash
}



