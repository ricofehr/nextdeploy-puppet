#! /bin/bash

# This script is executed as apache user, www-data, descend subversion

E_BADRUN=1
E_BADUSER=1
E_BADDOMAIN=1
E_BADARGS=65
CONSOLEPATH="app/console"

rc=0

echo "########";
    export LANG=fr_FR.UTF-8
    echo "# Updating \"$1server\"";
    cd $1/server
    [[ -f bin/console ]] && CONSOLEPATH="bin/console"
    /usr/bin/php $CONSOLEPATH doctrine:schema:update --force
    /usr/bin/php $CONSOLEPATH assets:install --symlink
    /usr/bin/php $CONSOLEPATH | grep assetic >/dev/null 2>&1 && /usr/bin/php $CONSOLEPATH assetic:dump
    /usr/bin/php $CONSOLEPATH cache:clear

    rc=$?;
echo "########";

# Exit
#exit 0;
exit $rc;
