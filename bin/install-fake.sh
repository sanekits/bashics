#!/bin/bash
# install-fake.sh

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
        [[ -h ./bashics ]] && die "bashics is already fake-installed: $(command ls -ald "$./bashics")"
        [[ -d ./bashics ]] && mv ./bashics ./bashics-bak.$$
        ln -sf "${scriptDir}" ./bashics
    )
}

if [[ -z "${sourceMe:-}" ]]; then
    main "$@"
    builtin exit
fi
command true
