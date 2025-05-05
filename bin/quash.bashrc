#!/bin/bash
# quash.bashrc
# Loaded at shell init time usually.  Define the current-shell elements
# for quash support

export _QUASH_BIN=${_QUASH_BIN:-"${HOME}/.local/bin/bashics"}

quash() {
    #shellcheck disable=1091
    _QNEW=false
    if [[ -z ${_QUASH_TOPLVL:-} ]]; then
            _qSourceMe=1 _QNEW=true source ${_QUASH_BIN}/quash.sh
            return
    else
        _qSourceMe=1 source "${_QUASH_BIN}/quash.sh" "$@"
    fi
}



