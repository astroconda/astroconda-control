if [[ -z $context ]]; then
    context=unknown
fi

if [[ -z $name ]]; then
    name=unknown
fi

if [[ -z $test_to ]]; then
    echo "\$test_to undefined. I refuse to continue. Did you forget to include pre-common?"
    exit 1
fi

PYTHON_VERSION=$(python --version 2>&1 | awk '{ print $2 }')
CPU_COUNT=`python -c 'import multiprocessing as mp; print(mp.cpu_count()-1)'`

DATETIME=$sm_run
if [[ -z $DATETIME ]]; then
    echo "sm_run was undefined!"
    DATETIME=broken_time_`date '+%Y-%m-%d-%H-%M-%s'`
fi

export LOGDIR="$test_to/$context"
mkdir -p "$LOGDIR"

if [[ -z $PDK_TESTRUN ]]; then
    export PDK_TESTRUN=${name}-${DATETIME}
fi
export PDK_CONTEXT=$context:${PYTHON_VERSION}
export PDK_LOG="$LOGDIR/${HOSTNAME}-$PDK_TESTRUN"

echo '----'
echo "Applying SHELL fix (thanks Continuum)..."
if [[ $SHELL == bash ]]; then
    export SHELL=/bin/bash
elif [[ $SHELL == zsh ]]; then
    export SHELL=/bin/zsh
else
    # Don't ask why...
    export SHELL=/bin/bash
fi

echo '----'
printenv

