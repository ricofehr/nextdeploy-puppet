#!/bin/bash

DOCROOTGIT="$1"
COMMITHASH="$2"
[[ -z "$DOCROOTGIT" ]] && exit 1
[[ -z "$COMMITHASH" ]] && exit 1
[[ ! -d "${DOCROOTGIT}/.git" ]] && exit 1

pushd $DOCROOTGIT >/dev/null
git reset --hard ${COMMITHASH}
(($? != 0)) && git reset --hard HEAD
popd >/dev/null
