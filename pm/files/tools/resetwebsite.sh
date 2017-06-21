#!/bin/bash

DOCROOTGIT="$1"
[[ -z "$DOCROOTGIT" ]] && exit 1
[[ ! -d "${DOCROOTGIT}/.git" ]] && exit 1

service puppet stop
[[ -f /var/lib/puppet/./state/agent_catalog_run.lock ]] && sleep 60
rm -rf $DOCROOTGIT
rm -f /home/modem/.deploy*
puppet agent -t
service puppet start
