#!/bin/bash

function logger
{
    local logfile="$1"
    if [[ $logfile != *.log ]]; then
        echo "logger: log file is missing .log prefix, '$logfile'"
        exit 1
    fi

    shift

    # Bash magic: return this exit value for the first pipe command
    echo "Writing log: $logfile"
    set -o pipefail
    "$@" 2>&1 | tee $logfile
    retval=$?
    set +o pipefail

    return $retval
}

