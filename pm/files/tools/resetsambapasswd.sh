#!/bin/bash

[[ $UID != 0 ]] && exit 99
modempasswd="$1"
[[ -z "$modempasswd" ]] && exit 98
echo -en "${modempasswd}\n${modempasswd}\n" | pdbedit -a modem -t