#!/bin/bash
source /eng/ssb/auto/astroconda/include/midnight_special.sh
source /eng/ssb/auto/astroconda/include/pre-common.sh
hostname=`hostname`

case "$hostname" in
    ssbwebv1*)
        echo processing okify records in pandokia database
    ;;
    *)
        echo $hostname cannot perform this action
        exit 1
    ;;
esac

# The only 'irafdev' gave us that we actually needed...
export PATH=/usr/stsci/pyssgdev/Python-2.7.1/bin:$PATH
export PYTHONPATH=/home/iraf/py/lib/python:/usr/stsci/pyssgdev/2.7.1.stsci_python:/usr/stsci/pyssgdev/2.7.1

# Pandokia specific (rather not clobber these together)
export N=82
export PATH=/ssbwebv1/data2/pandokia/c$N/bin:$PATH
export PYTHONPATH=/ssbwebv1/data2/pandokia/c$N/lib/python/:$PYTHONPATH

which pdk

set -x

pdk ok

set +x

exit $?
