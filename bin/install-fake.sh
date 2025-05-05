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
    local mode="${1:install}"
    case $mode in 
        install)
            (
                cd "${HOME}/.local/bin"
                [[ -h ./bashics ]] && die "bashics is already fake-installed: $(command ls -ald ./bashics)"
                [[ -d ./bashics ]] && {
                    mv ./bashics ./bashics-bak.$$
                    rm ./bashics-bak.latest &>/dev/null || :
                    ln -sf ./bashics-bak.$$ ./bashics-bak.latest
                    ln -sf "${scriptDir}" ./bashics
                    echo "install complete"
                }
                return
            )
            ;;
        uninstall)
            (
                cd "${HOME}/.local/bin"
                [[ -h ./bashics ]] || die "bashics is not fake-installed: $(command ls -ald ./bashics)"
                rm bashics
                xlatest=$(readlink -f ./bashics-bak.latest)
                [[ -d $xlatest ]] || die "Incoherent bashics-bak.latest"
                mv "$xlatest" bashics
                rm bashics-bak.latest
                echo "uninstall complete"
            )
            ;;
        *)
            die bad mode "$mode"
            ;;
    esac
}

if [[ -z "${sourceMe:-}" ]]; then
    main "$@"
    builtin exit
fi
command true
