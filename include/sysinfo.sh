function check_which
{
    path="$1"
    which $path &>/dev/null
    status=$?
    echo "$status"
}

# For conda INSTALLERS
sysinfo_platform=`uname`
case $sysinfo_platform in
    Darwin)
    sysinfo_platform="MacOSX"
    ;;
    *) ;;
esac

sysinfo_arch=`uname -m`
case $sysinfo_arch in
    i*86)
    sysinfo_arch="x86"
    ;;
    *) ;;
esac

case $sysinfo_platform in
    Linux)
    sysinfo_fetch="wget"
    sysinfo_fetch_args="-q"
    ;;
    *)
    sysinfo_fetch="curl"
    sysinfo_fetch_args="-s -L -O"
    ;;
esac

# For conda BUILDS
function conda_arch
{
    local platform=
    local arch=

    case `uname` in
        Linux)
            platform="linux"
        ;;
        Darwin)
            platform="osx"
        ;;
        *)
            echo "Unsupported platform."
            exit 1
        ;;
    esac

    case `uname -m` in
        i*86)
            arch=32
        ;;
        x86_64)
            arch=64
        ;;
        *)
            echo "Unsupported architecture."
            exit 1
        ;;
    esac

    echo "${platform}-${arch}"    
}
