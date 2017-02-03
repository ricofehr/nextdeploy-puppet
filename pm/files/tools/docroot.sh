#!/bin/bash

DOCROOTGIT="$1"
URIFOLDER="$2"
[[ -z "$DOCROOTGIT" ]] && exit 1
[[ -z "$URIFOLDER" ]] && exit 1

pushd $DOCROOTGIT >/dev/null
(( $? != 0 )) && exit 1

# docroot exists already and is a folder
if [[ -d $URIFOLDER ]]; then
  popd > /dev/null
  exit 0
fi

# docroot exists already but is a symlink
if [[ -h $URIFOLDER ]]; then
  test -d "$(readlink $URIFOLDER | tr -d "\n")" && exit 0
  mkdir -p $(readlink $URIFOLDER | tr -d "\n")
  (( $? != 0 )) && exit 1
  popd > /dev/null
  exit 0
fi

# docroot dont exists
if [[ ! -e $URIFOLDER ]]; then
  mkdir -p $URIFOLDER
  (( $? != 0 )) && exit 1
  popd > /dev/null
  exit 0
fi

popd > /dev/null
