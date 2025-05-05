#!/bin/bash
# install-fake.sh
#shellcheck disable=2154
PS4='\033[0;33m$( _0=$?;set +e;exec 2>/dev/null;realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} \033[0;35m^$_0\033[32m ${FUNCNAME[0]:-?}()=>" )\033[;0m '

scriptName="${scriptName:-"$(command readlink -f -- "$0")"}"
scriptDir="$(command dirname -- "${scriptName}")"
[[ -n "${DEBUGSH:-}" ]] && set -x

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}

main() {
    set -ue
    set -x
    (
        cd "${HOME}/.local/bin"
        [[ -h ./bashics ]] && die "bashics is already fake-installed: $(command ls -ald ./bashics)"
        [[ -d ./bashics ]] && mv ./bashics ./bashics-bak.$$
        ln -sf "${scriptDir}" ./bashics
    )
}

if [[ -z "${sourceMe:-}" ]]; then
    main "$@"
    builtin exit
fi
command true
