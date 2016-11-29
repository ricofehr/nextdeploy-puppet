#!/bin/bash

EPPATH=""
DOCROOT=""
USERNAME=""
ADMINPASS=""
PROJECT=""
EMAIL=""
PROFILE=""

# Parse cmd options
while (($# > 0)); do
  case "$1" in
    --docroot)
      shift
      DOCROOT="$1"
      shift
      ;;
    --eppath)
      shift
      EPPATH="$1"
      shift
      ;;
    --username)
      shift
      USERNAME="$1"
      shift
      ;;
    --adminpass)
      shift
      ADMINPASS="$1"
      shift
      ;;
    --project)
      shift
      PROJECT="$1"
      shift
      ;;
    --email)
      shift
      EMAIL="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# set env for drush cmd
export HOME=/home/modem
export USER=modem
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export SHELL=/bin/bash
export TERM=xterm

pushd $DOCROOT >/dev/null

if [[ -d profiles ]]; then
  pushd profiles >/dev/null
  # define profile to install
  PROFILE="$(find . -maxdepth 1 -type d -regex '^.*nextdeploy_.*$' | sed "s;./;;" | tr -d "\n")"
  popd >/dev/null
fi
[[ -z "$PROFILE" ]] && PROFILE="standard"

# launch install
/usr/local/bin/drush -y site-install --db-url=mysql://s_bdd:s_bdd@localhost:3306/${EPPATH} --locale=en --account-name=${USERNAME} --account-pass=${ADMINPASS} --site-name=${PROJECT} --account-mail=${EMAIL} --site-mail=${EMAIL} $PROFILE >/home/modem/logsiteinstall 2>&1
popd > /dev/null
