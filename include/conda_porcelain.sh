#!/bin/sh
source /eng/ssb/auto/astroconda/include/sysinfo.sh
porcelain_continuum_url=https://repo.continuum.io/miniconda
porcelain_continuum_script=Miniconda3-latest-${sysinfo_platform}-${sysinfo_arch}.sh
porcelain_extra_config=/eng/ssb/auto/astroconda/etc/porcelain-extra
PORCELAIN_ALREADY_DEAD=0
PORCELAIN_SIGNALED=0

function porcelain_init
{
    echo "Porcelain initializing..."
    if [[ -z $HOME ]]; then
        echo "\$HOME is not set, dying."
        exit 1
    fi
    
    export TMPDIR="$HOME/bldtmp"
    
    if [[ ! -d $TMPDIR ]]; then
        mkdir -p $TMPDIR
        if [[ $? != 0 ]]; then
            echo "Cannot create temporary storage directory '$TMPDIR', dying."
            exit 1
        fi
    fi

    export PORCELAIN_PREFIX=`mktemp -d -t porcelain.XXXXXXXXXX` 
    export PORCELAIN_TMPDIR="$PORCELAIN_PREFIX/tmp"
    export PORCELAIN_DESTDIR="$PORCELAIN_PREFIX/porcelain"
    export PATH="$PORCELAIN_DESTDIR/bin:$PATH"
    echo "Prepended $PORCELAIN_DESTDIR/bin to PATH..."

    if [[ ! -d $PORCELAIN_TMPDIR ]]; then
        mkdir -p "$PORCELAIN_TMPDIR"
    fi

    export TMPDIR="$PORCELAIN_TMPDIR"
    echo "Redirected TMPDIR to $PORCELAIN_TMPDIR"
    echo "(Always use \$TMPDIR instead of /tmp for destructible storage)"
    
    echo "Activating signal handler... (will deinit on exit)"
    trap porcelain_signal SIGINT SIGKILL SIGTERM EXIT
}

function porcelain_verify
{
    local override="$1"
    /bin/echo -n "Running safety check... "

    if [[ $override == '-f' ]] || [[ $override == '--force' ]]; then
        echo "done (forced)"
        return 0
    fi

    if [[ -z $TMPDIR ]]; then
        echo "failed"
        echo "TMPDIR='$TMPDIR'; we have lost trust in our environment. Dying."
        exit 1
    fi

    if [[ ! -d $PORCELAIN_PREFIX ]]; then
        echo "failed"
        echo "PORCELAIN_PREFIX='$PORCELAIN_PREFIX'; mktemp must have failed. Dying."
        exit 1
    fi

    # Note: we don't care about PORCELAIN_DESTDIR
    echo "done"
}

function porcelain_get_installer
{
    porcelain_verify

    retries=3
    wtime=5
    success=0
    count=0

    echo "Obtaining $porcelain_continuum_script..."

    while [[ $count != $retries ]]
    do
        $sysinfo_fetch $sysinfo_fetch_args "$porcelain_continuum_url/$porcelain_continuum_script"
        if [[ $? == 0 ]]; then
            success=1
            break
        fi

        echo "Retrying in $wtime second(s)..."
        sleep $wtime
        count=$(( count + 1 ))
    done

    if [[ $success != 1 ]]; then
        echo "Dying..."
        exit 1
    fi
}

function porcelain_run_installer
{
    porcelain_verify

    bash $porcelain_continuum_script -b -p $PORCELAIN_DESTDIR
    if [[ $? > 0 ]]; then
        echo "Dying..."
        exit 1
    fi

    # do extraneous package installation
    porcelain_extra_install
}

function porcelain_extra_install
{
    if [[ -f $porcelain_extra_config ]]; then
        porcelain_verify

        while read pkg
        do
            if [[ $pkg == "" ]]; then
                continue
            elif [[ $pkg == "#"* ]]; then
                continue
            fi

            conda install -y -q $pkg
        done < $porcelain_extra_config
    fi
}

function porcelain_deinit
{
    if [[ $PORCELAIN_ALREADY_DEAD != 0 ]]; then
        return
    fi

    porcelain_verify

    echo "Deinitializing porcelain..."
    if [[ -d $PORCELAIN_PREFIX ]]; then
        echo "Removing $PORCELAIN_PREFIX"
        rm -rf "$PORCELAIN_PREFIX"
    fi
    export PORCELAIN_ALREADY_DEAD=1
}

# Given the chance this script could be killed in a number of different
# ways, resulting in files left behind... we need to be pretty damn
# thourough.
function porcelain_signal
{
    # Obtain last return value
    retval=$?

    # If error.sh recorded errors; use the count instead
    if [[ -n $_E_COUNT ]] && [[ $_E_COUNT > 0 ]]; then
        retval=$_E_COUNT
    fi

    # Already signaled, so die
    if [[ $PORCELAIN_SIGNALED != 0 ]]; then
        exit $retval
    fi

    # If error.sh has been activated; display error report
    if [[ -n $_E_FLAGS ]] && [[ $_E_FLAGS != 0 ]]; then
        echo '----'
        error_report
    fi

    export PORCELAIN_SIGNALED=1
    porcelain_deinit

    exit $retval
}

