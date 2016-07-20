#!/bin/bash
source /eng/ssb/auto/astroconda/include/midnight_special.sh
source /eng/ssb/auto/astroconda/include/pre-common.sh

# Set context (used here and in post-common.sh)
name=conda
context=dev
repo=http://ssb.stsci.edu/conda-dev

# Activate environment
source activate rt_${context}27

# Update environment
conda update -q -y --override-channels -c defaults -c $repo --all

source /eng/ssb/auto/astroconda/include/post-common.sh

# Assign tests to run
tests=(
    $test_from/general
    $test_from/more_tests
    $test_from/test_functions
)

# Nuke existing logs, run the tests, import the tests
set -x

[[ -d $LOGDIR ]] && [[ $LOGDIR != ^/$ ]] && rm -f "$LOGDIR/*"
pushd $LOGDIR
    time pdkrun --parallel=${CPU_COUNT} -r "${tests[@]}"
popd
cat ${PDK_LOG}* | ssh iraf@ssb "irafdev ; pdk import -"

