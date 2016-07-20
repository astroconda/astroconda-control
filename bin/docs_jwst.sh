#!/bin/bash
source /eng/ssb/auto/astroconda/include/midnight_special.sh
source /eng/ssb/auto/astroconda/include/conda_porcelain.sh
source /eng/ssb/auto/astroconda/include/texlive.sh

porcelain_init

pushd "$PORCELAIN_PREFIX"
    porcelain_get_installer
    porcelain_run_installer
    
    build_env="$(basename $PORCELAIN_PREFIX)"
    depot=/eng/ssb/websites/ssbpublic/doc/jwst_git
    
    repo_conda=http://ssb.stsci.edu/conda-dev
    repo_git=https://github.com/stsci-jwst/jwst
    repo_git_branch=master
    
    conda create -n "$build_env" \
        --yes \
        --quiet \
        --override-channels \
        -c defaults \
        -c $repo_conda sphinx=1.3.5 jwst stsci.sphinxext

    source activate $build_env

    git clone "$repo_git"
    pushd "$(basename $repo_git)"
        git checkout $repo_git_branch
        docs/mkdocs.sh -o "$depot"
    popd
popd

porcelain_deinit

