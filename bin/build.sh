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
# out of $PORCELAIN_PREFIX or $TMPDIR prior to exiting the script or calling
# "porcelain_deinit" directly.
#
# A signal handler is in place to run "porcelain_deinit" automatically on
# exit regardless of exit method. Signals and general exit calls are ALL
# handled equally.
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

source /eng/ssb/auto/astroconda/include/midnight_special.sh
source /eng/ssb/auto/astroconda/include/sysinfo.sh
source /eng/ssb/auto/astroconda/include/conda_porcelain.sh
source /eng/ssb/auto/astroconda/include/logger.sh

function warning_sleep
{
    wtime=$1
    if [[ -z $wtime ]]; then
        wtime=30
    fi

    echo "YOU PROBABLY DO NOT WANT THIS!"
    echo "Sleeping for $wtime second(s) just in case."
    #sleep $wtime
    echo "Continuing..."
}

function repo_transfer
{
    porcelain_verify

    local repo_local="$PORCELAIN_DESTDIR/conda-bld/$repo_arch"
    local path="$1"

    if [[ -z $path ]]; then
        echo "transfer_repo requires a path."
        exit 1
    fi

    if [[ $path == *${repo_arch} ]]; then
        echo "tranfer_repo received an invalid path: $path"
        echo "(Remove the trailing /$repo_arch)"
        exit 1
    fi

    echo "Transfering local repository $repo_local to $path"
    rsync -aHv \
        --exclude='repodata*' \
        --exclude='.index*' \
        "$repo_local" \
        "$path/"

    retval=$?
    if [[ $retval > 0 ]]; then
        exit $?
    fi
}

function repo_index
{
    local path="$1"
    if [[ -z $path ]]; then
        echo "index_repo requires a path"
        exit 1
    fi

    if [[ ! -d $path ]]; then
        echo "$path does not exist."
        exit 1
    fi

    echo "Indexing remote repository: $path"
    conda index $path

    retval=$?
    if [[ $retval > 0 ]]; then
        exit $retval
    fi
}

function usage
{
    printf "%s: [-h] [-bm] (-p|-d)\n" $(basename $0)
    echo "
    Optional:

    --bootstrap         -B  Build regardless if package exists upstream
                            (Dangerous)
    --branch [branch]   -b  Desired git branch 
                            (OMIT trailing os-arch; e.g. /linux-64)
    --help              -h  This message
    --manifest [file]   -m  Ordered build list

    Required:

    --public            -p  Use public (astroconda)
    --dev               -d  Use dev    (astroconda-dev)
    --deposit [path]    -D  Destination for completed packages
    --numpy [version]   -N  NumPy linkage version
    --python [version]  -P  Python linksage version
    "
}

# 775 | 664
umask 002

build_bootstrap=0
muarg_public=0
muarg_dev=0


if [[ $# < 1 ]]; then
    usage
    exit 1
fi

while [[ $# > 0 ]]
do
    key="$1"
    case "$key" in
        --help|-h)
            usage
            exit 0
        ;;
        --branch|-b)
            repo_git_branch="$2"
            if [[ $repo_git_branch == -* ]] || [[ -z $repo_git_branch ]]; then
                echo "--branch/-b requires an argument."
                exit 1
            fi
            shift
        ;;
        --deposit|-D)
            repo_deposit="$2"
            if [[ $repo_deposit == -* ]] || [[ -z $repo_deposit ]]; then
                echo "--deposit requires an argument."
                exit 1
            fi
            shift
        ;;
        --python|-P)
            build_python="$2"
            if [[ $build_python == -* ]] || [[ -z $build_python ]]; then
                echo "--python requires an argument."
                exit 1
            fi
            shift
        ;;
        --numpy|-N)
            build_numpy="$2"
            if [[ $build_numpy == -* ]] || [[ -z $build_numpy ]]; then
                echo "--numpy requires an argument."
                exit 1
            fi
            shift
        ;;
        --public|-p)
            muarg_public=1
            if [[ $muarg_dev != 0 ]]; then
                echo "--public is mutually exclusive with --dev"
                exit 1
            fi
            repo_git=https://github.com/astroconda/astroconda-contrib
            repo_conda=http://ssb.stsci.edu/astroconda
        ;;
        --dev|-d)
            muarg_dev=1
            if [[ $muarg_public != 0 ]]; then
                echo "--dev is mutually exclusive with --public"
                exit 1
            fi
            repo_git=https://github.com/astroconda/astroconda-dev
            repo_conda=http://ssb.stsci.edu/conda-dev
        ;;
        --manifest|-m)
            build_manifest="$2"
            if [[ ! -f $build_manifest ]]; then
                echo "'$build_manifest' does not exist."
                exit 1
            fi
            shift
        ;;
        --bootstrap|-B)
            build_bootstrap=1
        ;;
        *)
            usage
            echo "Unknown argument: $1"
            echo
            exit 1
        ;;
    esac
    shift
done

if [[ -z $repo_git ]]; then
    echo "Missing argument: --public or --dev is required"
    exit 1
elif [[ -z $repo_deposit ]]; then
    echo "--deposit is required"
    exit 1
elif [[ -z $build_python ]]; then
    echo "--python is required"
    exit 1
elif [[ -z $build_numpy ]]; then
    echo "--numpy is required"
    exit 1
fi

if [[ -z $repo_git_branch ]]; then
    repo_git_branch=master
fi

if [[ ! -d $repo_deposit ]]; then
    mkdir -p $repo_deposit
    retval=$?
    if [[ $? > 0 ]]; then
        echo "Unable to create $repo_deposit"
        exit 1
    fi
fi

# Set repository tail
repo_arch=`conda_arch`

echo repo_git_branch=$repo_git_branch
echo repo_git=$repo_git
echo repo_deposit=$repo_deposit
echo repo_arch=`conda_arch`
echo build_python=$build_python
echo build_numpy=$build_numpy
echo build_manifest=$build_manifest

if [[ $build_bootstrap != 0 ]]; then
    echo "BOOTSTRAP MODE ACTIVE (DANGEROUS)"
    warning_sleep 90
fi

if [[ -z $build_manifest ]]; then
    echo "No manifest defined; building alphabetically."
    warning_sleep 90
fi

build_command="conda build \
    --quiet \
    --python=$build_python \
    --numpy=$build_numpy \
    --override-channels \
    -c defaults"

if [[ $build_bootstrap == 0 ]]; then
    build_command="$build_command --skip-existing -c $repo_conda"
else
    echo "Bootstrap mode is active... FINAL WARNING!"
    warning_sleep 10
fi


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

    conda install --yes --quiet conda-build=1.18.1 conda=3.19.1
    if [[ $? > 0 ]]; then
        echo "Unable to install conda-build, so stopping."
        exit 1
    fi
    echo

    git clone $repo_git
    if [[ $? > 0 ]]; then
        echo "Unable to clone recipe repository $repo_git, so stopping."
        exit 1
    fi
    echo

    pushd "$(basename $repo_git)"
        if [[ -n $build_manifest ]]; then
            for pkg in $(cat $build_manifest)
            do
                if [[ -z $pkg ]] || [[ $pkg == \#* ]]; then
                    continue
                fi

                logger $LOGDIR/${pkg}.log $build_command $pkg
            done
        else
            # Pretty much the worst thing you could ever WANT to do...
            # this will build things you DO NOT WANT. Use a manifest!
            for pkg in *
            do
                [[ ! -f $pkg/meta.yaml ]] && continue
                logger $LOGDIR/${pkg}.log $build_command $pkg
            done
        fi

        echo '----'
        logger repo_transfer.log repo_transfer "$repo_deposit"
        echo '----'
        logger repo_index.log repo_index "$repo_deposit/$repo_arch"
        echo '----'
    popd
popd

porcelain_deinit

