#! /bin/bash

# This script is executed as apache user, www-data, descend subversion

E_BADRUN=1
E_BADUSER=1
E_BADDOMAIN=1
E_BADARGS=65


if [ $# -lt 1 ];
then
    echo "Usage: `basename $0` DOCUMENTROOT BRANCHE";
    exit $E_BADARGS;
fi

DM0=$1
DM=${1%%/}
tag="HEAD"

umask 027
rc=0;

echo "########";
if [ ! -e $1 ]
then
	echo "# Unable to find directory \"$1\" or git is not initialized!";
	rc=$E_BADARGS;
else
	export LANG=fr_FR.UTF-8
	echo "# Updating \"$DM0\"";
	[[ -n "$2" ]] && tag=$2
	pushd $DM0 >/dev/null
        [[ -d server/sites ]] && chmod u+w server/sites/* && chmod u+w server/sites/*/settings.php && chmod u+w server/sites/*/*.settings.php
	git reset --hard HEAD 2>&1&&git pull --rebase origin 2>&1
	(($? != 0)) && exit 66

	test -n "$2" && git fetch --tags origin
	sha1=$(git rev-parse ${tag})
	(($? != 0)) && echo "invalid tag ${tag}" && exit 66
	sha1=${sha1:0:7}
	(($? != 0)) && echo "invalid tag ${tag}" && exit 66
	git log --pretty=oneline | grep "^${sha1}"
	(($? != 0)) && echo "invalid tag ${tag}" && exit 66	
	git reset --hard ${sha1} 2>&1

        if test -f .gitmodules; then
          git submodule update --init --recursive
        fi

	rc=$?
        # drupal site
	if [[ -d server/sites ]]; then
          chmod u-w server/sites/*
          chmod u-w server/sites/*/settings.php
          chmod u-w server/sites/*/*.settings.php
          pushd server >/dev/null
          drush cc all
          popd > /dev/null
        fi

        # symfony site
        if [[ -f server/app/console ]]; then
          php server/app/console cache:clear --env=dev
          php server/app/console cache:clear --env=prod
          php server/app/console assets:install --symlink
          php server/app/console assetic:dump
        fi
	popd > /dev/null
fi
echo "########";

rm -f ${TESTMEP}
exit $rc;
