#!/bin/bash

DOCROOT="$1"
[[ -z "$DOCROOT" ]] && exit 1
[[ ! -f /usr/bin/php ]] && echo "No php binary found" && exit 0

[[ -z "$LANG" ]] && export LANG=en_US.UTF-8
[[ -z "$HOME" ]] && export HOME=/var/www

pushd $DOCROOT >/dev/null
(( $? != 0 )) && exit 1
find . -maxdepth 6 -name composer.json | grep -v "vendor" | while read GFILE; do
  pushd "${GFILE%/*}" >/dev/null
  [[ -f composer.phar ]] && rm -f composer.phar
  curl -sS https://getcomposer.org/installer | php
  /usr/bin/php composer.phar install -n --prefer-source
  rm -f composer.phar
  popd >/dev/null
done
popd > /dev/null