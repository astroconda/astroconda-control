#!/bin/bash
source /eng/ssb/auto/astroconda/include/midnight_special.sh
source /eng/ssb/auto/astroconda/include/pre-common.sh

source activate pandokia

if [ "$groupdir" = "" ]
then
    groupdir=/eng/ssb
else
    echo groupdir is:
    echo $groupdir
fi


# find our host name because it is used in the name of the okify file
h=`hostname -s`
echo $h

# where the okify files are
cd "$groupdir/tests/pdk_updates"

ls -l

if [[ ! -f $h.ok ]]; then
    echo no $h.ok
    exit 0
fi

# not processing directly from the active file
rm -f $h.ok.process
mv $h.ok $h.ok.process

echo START

set -x

pdk ok -w $h.ok.process
status=$?

set +x

echo END

exit $status

