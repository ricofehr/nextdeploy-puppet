#!/bin/bash

DOCROOT="$1"
[[ -z "$DOCROOT" ]] && exit 1

pushd $DOCROOT >/dev/null
(( $? != 0 )) && exit 1
find . -maxdepth 6 -name package.json | grep -v "node_modules" | while read GFILE; do 
  pushd "${GFILE%/*}" >/dev/null
  npm install
  grep '"build"' package.json >/dev/null 2>&1 && npm build
  popd >/dev/null
done

find . -maxdepth 6 -name bower.json | grep -v "node_modules" | while read GFILE; do 
  pushd "${GFILE%/*}" >/dev/null
  bower install
  popd >/dev/null
done

find . -maxdepth 6 -name Gruntfile.js | grep -v "node_modules" | while read GFILE; do 
  pushd "${GFILE%/*}" >/dev/null
  grunt build
  popd >/dev/null
done

find . -maxdepth 6 -name gulpfile.js | grep -v "node_modules" | while read GFILE; do 
  pushd "${GFILE%/*}" >/dev/null
  gulp build
  popd >/dev/null
done

popd > /dev/null