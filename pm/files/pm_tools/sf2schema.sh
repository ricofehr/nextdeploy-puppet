#! /bin/bash

# This script is executed as apache user, www-data, descend subversion

E_BADRUN=1
E_BADUSER=1
E_BADDOMAIN=1
E_BADARGS=65

rc=0

echo "########";
    export LANG=fr_FR.UTF-8
    echo "# Updating \"$1server\"";
    cd $1/server
    /usr/bin/php app/console doctrine:schema:update --force
    /usr/bin/php app/console assets:install --symlink
    /usr/bin/php app/console assetic:dump
    /usr/bin/php app/console cache:clear

    rc=$?;
echo "########";

# Exit
#exit 0;
exit $rc;
