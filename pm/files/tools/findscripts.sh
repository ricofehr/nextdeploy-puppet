#!/bin/bash

find . -regex '^.*\.sh$' | grep -v "/vendor/" | while read SCRIPTS; do
  echo "$(echo "${SCRIPTS%/*}" | sed "s;^./;;"),${SCRIPTS##*/}"
done