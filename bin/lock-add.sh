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

See also: await-no-locks.sh

XEOF
}

[[ -z ${sourceMe} ]] && {
    locknames=()
    lock_pid=$$
    lock_dir=$PWD
    lock_context=NONE
    while [[ -n $1 ]]; do
        case $1 in
            --pid) lock_pid=$2; shift ;;
            --context) lock_context=$2; shift ;;
            --dir) lock_dir=$2; shift;;
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
    result=0
    for lock_name in ${lock_names[@]}; do
        {
            echo "name=$lock_name"
            echo "context=$lock_context"
            echo "pid=$lock_pid"
        } > "${lock_name}.tmp$$.lock"
        [[ -f "${lock_name}.lock" ]] && {
            rm ${lock_name}.tmp$$.lock
            result=1;
            echo "(${script}) FAIL to obtain $lock_dir/$lock_name.lock - existing lock conflict: $(cat ${lock_name}.lock)" >&2 ;
            continue;
        }
        mv "${lock_name}.tmp$$.lock" "${lock_name}.lock"
    done

    builtin exit $result
}
command true
