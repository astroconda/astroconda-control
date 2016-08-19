function cleanup
{
    # Not a fan of ultra-verbose. This message will get lost.
    set +x
    echo "Trapped common exit signal (SIGINT | SIGTERM)"
    /bin/echo
    echo "TESTS WILL NOT BE IMPORTED"
    /bin/echo
    echo "Exiting..."
    exit 1
}
trap cleanup SIGINT SIGTERM

test_from=/srv/rt
test_to=~/local/pillowfort

if [[ `uname -s` == Darwin ]]; then
    test_from=/Users/iraf/rt
fi

if [[ $HOSTNAME == *jwcalibdev* ]]; then
    test_from=/data1/jwst_rt
fi

if [[ ! -d $test_to ]]; then
    mkdir -p "$test_to"
fi

export PATH=~/miniconda3/bin:$PATH
#export PATH=$PATH:~/local/fakedokia/bin
#export PYTHONPATH=~/local/fakedokia/lib
export CDBS=/grp/hst/cdbs/
export crrefer=$CDBS
export PYSYN_CDBS=$CDBS

function mkrt_paths
{
    args=("$@")
    paths=""

    for elem in "${args[@]}"
    do
        path="$test_from/$elem"
        if [[ ! -d $path ]]; then
            echo "Warning: $path does not exist. Omitting."
            continue
        fi
        paths+=($path)
    done
    printf $paths | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function svn_update()
{
    args=("$@")
    paths=""

    for elem in "${args[@]}"
    do
        if [[ ! -d $elem ]]; then
            echo "Warning: $elem does not exist. Omitting."
            continue
        fi

        pushd "$elem" &>/dev/null
            echo "Updating $elem ..."
            svn up --non-interactive --depth infinity --accept theirs-conflict
        popd &>/dev/null
        
    done
}
