#!/bin/bash
# Yeah, we're not dealing with the existing environment. Too many things can go wrong here.
# DROP EVERYTHING and start fresh in a different home directory
source /eng/ssb/auto/astroconda/include/host_config.sh

#[[ "$USER" != "" ]] && exec -c $0
if [[ -n $sm_run ]]; then
    export sm_base="$PWD"
fi

unset $(/usr/bin/env \
    | egrep '^(\w+)=(.*)$' \
    | egrep -vw 'SHLVL|USER|LANG|sm_run|sm_node|sm_logs|sm_base|node_dir|workdir|hostname' \
    | /usr/bin/cut -d= -f1)
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin
export HOME=$NEW_HOME
export TERM=xterm
source /etc/profile
source /etc/bashrc
#printenv
