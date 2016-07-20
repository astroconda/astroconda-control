#!/bin/bash
source /eng/ssb/auto/astroconda/include/sysinfo.sh

TL_HOME=/eng/ssb/sw/texlive

# Be realistic - I already know what's in there... 32/64-linux
if [[ $sysinfo_platform != Linux ]]; then
    echo "FATAL: $TL_HOME does not contain libraries for your platform."
    exit 1
fi

TL_PLATFORM=`$TL_HOME/install-tl --print-platform`
export PATH="$TL_HOME/bin/${TL_PLATFORM}:$PATH"

if [[ `which latex` != $TL_HOME/* ]]; then
    echo "WARNING: TexLive is not where we wanted it to be! $TL_HOME may be broken or missing."
else
    echo "Using TexLive: $TL_HOME"
fi


