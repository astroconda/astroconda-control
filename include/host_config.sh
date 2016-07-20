#(DEFAULT)
NEW_HOME=/srv/iraf

#JWST
if [[ $HOSTNAME == *jwcalibdev* ]]; then
    NEW_HOME=/data4/iraf_conda
fi

#OSX
if [[ `uname -s` == Darwin ]]; then
    NEW_HOME=/Users/shared/iraf_conda
fi

