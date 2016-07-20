#!/bin/bash
SRC=/eng/ssb/websites/ssbpublic/conda-dev
DST=/eng/ssb/websites/ssbpublic/astroconda-prerelease/

( cd $SRC \
    && rsync -aH --relative */*jwst* $DST \
    && conda index "$DST/linux-64" \
    && conda index "$DST/osx-64" \
    && cbc_repo2html "$DST/linux-64/repodata.json" > "$DST/linux-64/index.html" \
    && cbc_repo2html "$DST/osx-64/repodata.json" > "$DST/osx-64/index.html"
)
