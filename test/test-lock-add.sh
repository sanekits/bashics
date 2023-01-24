#!/bin/bash
# test-lock-add.sh

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

LockAdd=$(readlink -f ${scriptDir}/../bin/lock-add.sh)

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

stub() {
    # Print debug output to stderr.  Recommend to call like this:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    [[ -n $NoStubs ]] && return
    [[ -n $__stub_counter ]] && (( __stub_counter++  )) || __stub_counter=1
    {
        builtin printf "  <=< STUB(%d:%s)" $__stub_counter "$(basename $scriptName)"
        builtin printf "[%s] " "$@"
        builtin printf " >=> \n"
    } >&2
}

test_add_bulk() {
    local lockdir=locks.test_add_bulk
    rm -rf $lockdir 2>/dev/null || :
    mkdir $lockdir
    for vn in {000..199}; do
        mkdir -p ${lockdir}/user-${vn}.d
    done
    for vn in {000..199}; do
        ${LockAdd} --dir ${lockdir} --pid 1${vn} --context "this is it ${vn}" --block user-${vn}
        [[ -f ${lockdir}/user-${vn}.lock ]] || die "Lock creation fail at ${vn}"
    done

    mkdir -p eval.test_add_bulk
    cd $lockdir && {
        cat $(find . -type f | sort) > ../eval.test_add_bulk/all-content.txt
        find -type d | sort >> ../eval.test_add_bulk/all-content.txt
    }
    cd ../eval.test_add_bulk && {
        diff all-content.txt all-content-ref.txt || die "Failed comparing all-content.txt and all-content-ref.txt in $PWD"
    }
    echo "test_add_bulk(): OK"
}

main() {
    [[ -x ${LockAdd} ]] || die "can't find ${LockAdd}"
    test_add_bulk
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
