#!/bin/bash
#
# A steuermann compatible conda build script.
#
# This differs from the original build script in that it does not iterate over
# many Python or Numpy versions in an attempt to be fully comprehensive.
# Instead, since we're being "controlled", so we TELL steuermann what we want
# the script to perform at a high level (not this script), rather than making
# assumptions about what is needed/wanted at build-time.
#
# The build script uses "porcelain", and is not to be confused with "fragile".
#
# Conda uses lock files to determine whether its build (or installation)
# system is currently in use. Traditionally this means only ONE build may be
# active at a time. Porcelain installs its own miniconda into a completely
# unique temporary directory so that eliminates the problem entirely. The
# "conda build" subsystems never talk to one another while executing.

# You may run multiple builds at the same time so long as you activate
# porcelain [correctly] per-run.
#
# Porcelain is a write-once-remove-immediately, "WORI", enviroment. Yes,
# the name does imply "worry". Be sure to either copy or move important data
# out of $PORCELAIN_PREFIX or $TMPDIR prior to calling "porcelain_deinit".
#
# DO NOT FORGET TO RUN "porcelain_deinit".
#
# If you do, you will quickly fill up the partition. Builds can be as large
# as 4GB, and potentially larger as time goes on. Don't be a doofus; always
# run "porcelain_deinit". You have been warned.
#
# Never run a build outside of the "midnight_special" environment. The IRAF
# account is a total mess. "midnight_special" performs a magical ritutal
# that reassigns $HOME and effectively carpet bombs the original environment.
# Please do not modify "midnight_special" for any reason.
#

echo "BEFORE..."
printenv | sort
echo

source /eng/ssb/auto/astroconda/include/midnight_special.sh
source /eng/ssb/auto/astroconda/include/sysinfo.sh
source /eng/ssb/auto/astroconda/include/logger.sh
source /eng/ssb/auto/astroconda/include/conda_porcelain.sh

echo "AFTER..."
printenv | sort
echo

porcelain_init

# Setup logging
if [[ -n $sm_base ]]; then
    sm_logs="$sm_base/$sm_run/$sm_node"
fi

if [[ -n $sm_logs ]]; then
    if [[ ! -d $sm_logs ]]; then
        echo "Initializing steuermann log directory: $sm_logs"
        mkdir -p $sm_logs
    fi
fi

# Take note that we are testing $sm_base, not $sm_logs.
if [[ -n $sm_base ]]; then
    LOGDIR="$sm_logs"
else
    LOGDIR="$PORCELAIN_PREFIX/logs"
    mkdir -p "$LOGDIR"
fi
# Begin build processs
pushd "$PORCELAIN_PREFIX"
    porcelain_get_installer
    porcelain_run_installer

    logger $LOGDIR/a_test_file.log echo this output should be logged
popd

porcelain_deinit

