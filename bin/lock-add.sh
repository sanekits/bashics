#!/bin/bash
# lock-add.sh
#   See also await-no-locks.sh


scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
script=$(basename -- $scriptName)

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

do_help() {
    cat <<-XEOF
${script} name [name...]  [--pid <pid>] [--context <context>] [--dir <dir>]
  --dir: Directory to create .lock files, defaults to PWD
  --pid: written to pid= property in lockfile, defaults to \$\$
  --context: written to context= property in lockfile, defaults to NONE
  --block: Block until all locks acquired

See also: await-no-locks.sh

NOTE: If you use this in a loop which launches background subshells, it's
  important to add a "sleep 0.001" after each launch to let the previous
  process start before creating more lockfiles.

XEOF
}

NoStubs=1

stub() {
    # Print debug output to stderr.  Call like this:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    [[ -n $NoStubs ]] && return
    builtin echo -n "  <<< STUB" >&2
    for arg in "$@"; do
        echo -n "[${arg}] " >&2
    done
    echo " >>> " >&2
}

remove_name() {
    local remove_name name_list regex
    remove_name=$1; shift;
    name_list="$@"
    [[ -n $remove_name  ]] || {
        echo ; return;
    }
    [[ ${#name_list[@]} -eq 0 ]] && {
        echo ; return;
    }
    regex="^(.*)\b${remove_name}\b(.*)\$"
    [[ "${name_list[@]}" =~ $regex ]]
    echo "${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
}

[[ -z ${sourceMe} ]] && {
    locknames=()
    lock_pid=$$
    lock_dir=$PWD
    lock_context=NONE
    block=false
    while [[ -n $1 ]]; do
        case $1 in
            --pid) lock_pid=$2; shift ;;
            --context) lock_context=$2; shift ;;
            --dir) lock_dir=$2; shift;;
            --block) block=true ;;
            --help) do_help; exit;;
            -*) die "Unknown option: $1";;
            *)  lock_names+=( $1 );;
        esac
        shift
    done
    [[ ${#lock_names[@]} == 0 ]] \
        && exit 0
    cd $lock_dir \
        || die "Can't cd to --dir=$lock_dir"
    trap 'rz=$?; rm *.pend*.lock &>/dev/null; exit $rz;' SIGINT EXIT
    dx_outer=0
    while [[ ${#lock_names[@]} -gt 0 ]]; do
        (( dx_outer++ ))
        dx_inner=0
        for lock_name in ${lock_names[@]}; do
            (( dx_inner++ ))
            stub "${FUNCNAME[0]}.${LINENO}" "$dx_inner.$dx_outer" "P1"  lock_name=${lock_name}
            {
                echo "name=$lock_name"
                echo "context=$lock_context"
                echo "pid=$lock_pid"
            } > "${lock_name}.pend${lock_pid}.lock"
            [[ -f "${lock_name}.lock" ]] && {
                $block || \
                    echo "(${script}) FAIL to obtain $lock_dir/$lock_name.lock - existing lock conflict: $(cat ${lock_name}.lock)" >&2 ;
                continue;
            }
            stub "${FUNCNAME[0]}.${LINENO}" "$dx_inner.$dx_outer" "P_acquired" lock_name= "${lock_name}" lock_names= "${lock_names[@]}"
            # Lock can be acquired for this lock_name (note: lock acquisition is not strictly serialized here,
            # we just abort if a different pid beats us to the punch:)
            mv "${lock_name}.pend${lock_pid}.lock" "${lock_name}.lock"
            grep -Eq "^pid=${lock_pid}\$" "${lock_name}.lock" || die "Lock acquisition contention failed: $lock_pid vs [" $(cat ${lock_name}.lock | tr '\n' ' ' ) "]"
            lock_names=( $( remove_name ${lock_name} ${lock_names[@]} ) )
            stub "${FUNCNAME[0]}.${LINENO}" "$dx_inner.$dx_outer" "P__shift" lock_names= "${lock_names[@]}"
        done
        stub "${FUNCNAME[0]}.${LINENO}" "$dx_inner.$dx_outer" "P___pend_outer" lock_names= "${lock_names[@]}"
        [[ ${#lock_names[@]} -eq 0 ]] && {
            stub "${FUNCNAME[0]}.${LINENO}" "$dx_inner.$dx_outer" "P_exit_0_a"
            exit 0
        }
        $block || {
            stub "${FUNCNAME[0]}.${LINENO}" "$dx_inner.$dx_outer" "P_exit_1_a"
            exit 1
        }
        sleep 1  # We don't want to sleep on first pass
    done

    stub "${FUNCNAME[0]}.${LINENO}" $dx_inner.$dx_outer "P_exit_end" lock_names= "${lock_names[@]}"
    [[ ${#lock_names[@]} -eq 0 ]]; exit;
}
command true
