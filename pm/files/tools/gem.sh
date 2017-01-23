#!/bin/bash

DOCROOT="$1"
[[ -z "$DOCROOT" ]] && exit 1
[[ ! -f /usr/bin/gem ]] && echo "No gem binary found" && exit 0

[[ -z "$LANG" ]] && export LANG=en_US.UTF-8
[[ -z "$HOME" ]] && export HOME=/var/www

pushd $DOCROOT >/dev/null
(( $? != 0 )) && exit 1
find . -maxdepth 6 -name Gemfile | grep -v "vendor" | grep -v "node_modules" | while read GFILE; do
  pushd "${GFILE%/*}" >/dev/null
  echo "======= Gemfile in folder ${GFILE%/*} ======="
  sudo gem install bundler
  bundle install --path=vendor/bundle
  popd >/dev/null
done
popd > /dev/null
