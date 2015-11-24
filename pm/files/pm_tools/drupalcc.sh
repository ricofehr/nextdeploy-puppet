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
    # if d8, cr command
    # if d6 or d7, cc all
    drush status "Drupal version" | grep "8" >/dev/null 2>&1
    if (( $? == 0 )); then
      drush -y cr
    else
      drush -y cc all
    fi
    rc=$?;
echo "########";

# Exit
#exit 0;
exit $rc;
