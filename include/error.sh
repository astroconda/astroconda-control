#!/bin/bash

_E_WIDTH=15
_E_COUNT=0
_E_FLAGS=0
_E_FLAGS_STR=""

_E_FLAG_FAILURE=1
_E_FLAG_EXIT_STANDARD=2
_E_FLAG_EXIT_NONSTANDARD=4
_E_FLAG_EXIT_SIGNALED=8
_E_FLAG_EXIT_PEBKAC=16
_E_FLAG_HALT_AND_CATCH_FIRE=32
_E_FLAG_BAD_ARGUMENT=64
_E_FLAG_BAD_RETVAL=128
_E_FLAG_BAD_PACKAGE=256
_E_FLAG_RES4=512
_E_FLAG_RES5=1024
_E_FLAG_RES6=2048
_E_FLAG_RES7=4096
_E_FLAG_RES8=8192
_E_FLAG_RES9=16384
_E_FLAG_INTERNAL=32768
#_E_FLAG_UNUSED=65536

function error_mask_report
{
    local flags=$1

    for (( i=${_E_WIDTH}; i>=0; i-- ))
    do
        (( mask = flags & ( 1 << i ) ))
        case $mask in
            $_E_FLAG_FAILURE)
                echo "Script failed."
            ;;
            $_E_FLAG_EXIT_STANDARD)
                echo "Normal exit."
            ;;
            $_E_FLAG_EXIT_NONSTANDARD)
                echo "Non-standard exit."
            ;;
            $_E_FLAG_EXIT_SIGNALED)
                echo "Recievied signal."
            ;;
            $_E_FLAG_EXIT_PEBCAC)
                echo "Problem exists between keyboard and chair."
            ;;
            $_E_FLAG_HALT_AND_CATCH_FIRE)
                echo "A fatal error occurred."
            ;;
            $_E_FLAG_BAD_ARGUMENT)
                echo "Bad argument."
            ;;
            $_E_FLAG_BAD_RETVAL)
                echo "An external program exited abnormally."
            ;;
            $_E_FLAG_BAD_PACKAGE)
                echo "A package failed to build."
            ;;
            $_E_FLAG_RES4)
                echo "Reserved"
            ;;
            $_E_FLAG_RES5)
                echo "Reserved"
            ;;
            $_E_FLAG_RES6)
                echo "Reserved"
            ;;
            $_E_FLAG_RES7)
                echo "Reserved"
            ;;
            $_E_FLAG_RES8)
                echo "Reserved"
            ;;
            $_E_FLAG_RES9)
                echo "Reserved"
            ;;
            $_E_FLAG_INTERNAL)
                echo "Error handler experienced an internal error."
            ;;
            *)

            ;;
        esac
    done
}

function error_report
{
    local flags=`error_mask_string`
    printf "Error count: %16s\n" $_E_COUNT
    printf "Error mask:  %16s\n" $_E_FLAGS
    printf "Error flags: %16s\n" $flags
    echo "Error message(s):"
    while read line
    do
        echo "* $line"
    done< <(error_mask_report $_E_FLAGS)
}

function error_set
{
    local flag=$1
    if [[ -z $flag ]]; then
        echo "error.sh: Unable to set error flag: '$flag'"
        flag=$_E_FLAG_INTERNAL
    fi
    (( _E_FLAGS |= $flag ))
    (( _E_COUNT++ ))
    #echo "Error flag modified: $_E_FLAGS_STR"
}

function error_mask_string
{
    declare -a -i bits
    local flags=$_E_FLAGS
    local output=""

    for i in $(seq 0 $_E_WIDTH)
    do
        (( bits[i] = 0 ))
        (( bit = flags >> i ))
        if (( flags & ( 1 << i ) )); then
            (( bits[i] = 1 ))
        fi
    done
    
    for (( x=${_E_WIDTH}; x>=0; x-- ))
    do
        output+=$(( bits[x] ))
    done

    echo $output
}

