#! /bin/bash

# This script is executed as apache user, www-data, descend subversion

E_BADRUN=1
E_BADUSER=1
E_BADDOMAIN=1
E_BADARGS=65

if [ $# -ne 1 ];
then
    echo "Usage: `basename $0` DOCUMENTROOT";
    exit $E_BADARGS;
fi

# TODO: regexp check '/home/_site/[a-z\.\-]+/_online/'

rc=0;

echo "########";
    export LANG=fr_FR.UTF-8
    echo "# Updating \"$1server\"";
    cd $1/server
    /usr/bin/php composer.phar install -n --prefer-source

#if [[ -e bower.json ]]; then
#  source ~/nvm/nvm.sh && nvm use v0.10.29
#  bower install
#fi
    rc=$?;
echo "########";

# Exit
#exit 0;
exit $rc;
