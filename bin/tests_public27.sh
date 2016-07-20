#!/bin/bash
source /eng/ssb/auto/astroconda/include/midnight_special.sh
source /eng/ssb/auto/astroconda/include/pre-common.sh

# Set context (used here and in post-common.sh)
name=conda
context=public
repo=http://ssb.stsci.edu/astroconda

# Activate environment
source activate rt_${context}27

# Update environment
conda update -q -y --override-channels -c defaults -c $repo --all

source /eng/ssb/auto/astroconda/include/post-common.sh

# Assign tests to run
tests=(
    $test_from/astrolib
    $test_from/stsci_python
    $test_from/betadrizzle
    $test_from/axe
    $test_from/hstcal
    $test_from/stsdas
)

# Nuke existing logs, run the tests, import the tests
set -x

[[ -d $LOGDIR ]] && [[ $LOGDIR != ^/$ ]] && rm -f "$LOGDIR/*"
pushd $LOGDIR
    time pdkrun --parallel=${CPU_COUNT} -r "${tests[@]}"
popd
cat ${PDK_LOG}* | ssh iraf@ssb "irafdev ; pdk import -"

