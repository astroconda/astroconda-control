#!/bin/bash
source /eng/ssb/auto/astroconda/include/midnight_special.sh
source /eng/ssb/auto/astroconda/include/pre-common.sh

repo_base=http://ssb.stsci.edu
contexts=( dev public )
versions=( 27 35 )
tree_base=$(dirname $test_from)
trees=( rt rtx )

echo '----'
echo 'Updating base installation:'
conda update -q -y --all

echo '----'
for context in "${contexts[@]}"
do
    for version in "${versions[@]}"
    do
        case "$context" in
            dev)
                repo="$repo_base/conda-dev"
            ;;
            public)
                repo="$repo_base/astroconda"
            ;;
            *)
                echo "No repository available for: $context"
                exit 1
            ;;
        esac

        environ="rt_${context}${version}"
	if [[ ! -d ~/miniconda3/envs/$environ ]]; then
            echo '!!!!'
            echo "No Conda environment for: $environ"
            echo "Skipping..."
            continue
        fi
        echo '----'
        echo "Updating $context from $repo:"
        conda update -q -y --override-channels -c $repo -c defaults -n $environ --all
        echo '----'
        echo "Forcing pandokia to exist:"
        conda install -q -y --override-channels -c $repo -c defaults -n $environ pandokia
    done
done

echo '----'
echo 'Updating regression tests:'
for tree in "${trees[@]}"
do
    base="$tree_base/$tree"
    if [[ -d $base/.svn ]]; then
        svn_update $base
    fi
done
echo '----'

