#!/bin/bash
# test/quash-inline-test-1.sh


scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

source ${scriptDir}/../bin/quash.sh --inline "test1"

TRACE_PTY=/dev/pts/1
exec 9>${TRACE_PTY}

for ii in {0..3}; do
    _qbreak "ii=$ii"
    echo Continuing with ii=$ii
done
