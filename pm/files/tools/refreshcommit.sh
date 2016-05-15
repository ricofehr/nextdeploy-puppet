#!/bin/bash

[[ ! -d .git ]] && exit 0

NDURI="$1"
VM_NAME="$2"
BRANCH="$(git rev-parse --abbrev-ref HEAD | tr -d "\n")"
COMMITHASH="$(git rev-parse HEAD | tr -d "\n")"
COMMITID="${BRANCH}-${COMMITHASH}"

curl -X PUT --data-urlencode "commit_id=${COMMITID}" -k -s https://api.${NDURI}/api/v1/vms/${VM_NAME}/commit

exit 0