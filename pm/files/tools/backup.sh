#!/bin/bash


ISMYSQL=0
ISMONGO=0
FRAMEWORK=''
FTPUSER=''
FTPPASSWD=''
URI=''
VMNAME=''
FTPHOST='nextdeploy'
PATHURI="server"
DOCROOT="$(pwd)/"

# display helpn all of this parametes are setted during vm install
posthelp() {
  cat <<EOF
Usage: $0 [options]

-h                this is some help text.
--framework xxxx  framework targetting
--path xxxx       uniq path for the framework
--ftpuser xxxx    ftp user on nextdeploy ftp server
--ftppasswd xxxx  ftp password on nextdeploy ftp server
--ftphost xxxx    override nextdeploy ftp host
--ismysql x       1/0 if mysql-server present (default is 0)
--ismongo x       1/0 if mysql-server present (default is 0)
--vmname xxxx     name of vm
--uri xxxx        uri of the website
EOF

exit 0
}


# Parse cmd options
while (($# > 0)); do
  case "$1" in
    --framework)
      shift
      FRAMEWORK="$1"
      shift
      ;;
    --ftpuser)
      shift
      FTPUSER="$1"
      shift
      ;;
    --ftppasswd)
      shift
      FTPPASSWD="$1"
      shift
      ;;
    --ftphost)
      shift
      FTPHOST="$1"
      shift
      ;;
    --ismysql)
      shift
      ISMYSQL="$1"
      shift
      ;;
    --ismongo)
      shift
      ISMONGO="$1"
      shift
      ;;
    --path)
      shift
      PATHURI="$1"
      shift
      ;;
    --uri)
      shift
      URI="$1"
      shift
      ;;
    --vmname)
      shift
      VMNAME="$*"
      shift
      ;;
    -h)
      shift
      posthelp
      ;;
    *)
      shift
      ;;
  esac
done

DOCROOT="${DOCROOT}${PATHURI}"

# drupal actions
postdrupal() {
  # compress assets archive
  assetsarchive "${DOCROOT}/sites/default/files"
  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # export data
  backupdatas
}

# symfony actions
postsymfony2() {
  # decompress assets archive
  assetsarchive "${DOCROOT}/web/uploads"
  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # export datas
  backupdatas
}

# wordpress actions
postwordpress() {
  # decompress assets archive
  assetsarchive "${DOCROOT}/wp-content/uploads"
  (( $? != 0 )) && echo "No assets archive or corrupt file"

  # export datas
  backupdatas
}

# static actions
poststatic() {
  backupdatas
}

# export sql or mongo dump
backupdatas() {
  # sql part
  if (( ISMYSQL == 1 )); then
    backupsql
    if (( $? != 0 )); then
      echo "No sql file or corrupt file"
      (( ISMONGO == 0 )) && exit 0
    fi
  fi

  # mongo part
  if (( ISMONGO == 1 )); then
    backupmongo
    if (( $? != 0 )); then
      echo "No mongo file or corrupt file"
      exit 0
    fi
  fi
}

# export a sql dump into mysql server
backupsql() {
  local ret=0

  # prepare tmp folder
  rm -rf /tmp/dump
  mkdir /tmp/dump

  pushd /tmp/dump > /dev/null
  echo "show databases" | mysql -u s_bdd -ps_bdd | grep -v -e "^Database$" | grep -v -e "^information_schema$" | grep "${PATHURI}" | while read dbname; do
    mysqldump -u s_bdd -ps_bdd $dbname > ${VMNAME}_${dbname}.$(date +%u).sql
    gzip ${VMNAME}_${dbname}.$(date +%u).sql
    ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST backup/ "${VMNAME}_${dbname}.$(date +%u).sql.gz"
    (( $? != 0 )) && ret=1
  done
  popd > /dev/null
  rm -rf /tmp/dump
  return $ret
}

# export a mongo dump into mongoserver
backupmongo() {
  local ret=0

  # prepare tmp folder
  rm -rf /tmp/dump
  mkdir /tmp/dump

  pushd /tmp/dump > /dev/null
  echo "show dbs" | mongo --quiet | grep -v "local" | grep "${PATHURI}" | sed "s; .*$;;" | while read dbname; do
    mongodump --db $dbname
    pushd dump >/dev/null
    tar cvfz ${VMNAME}_${dbname}.$(date +%u).tar.gz $dbname
    ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST backup/ "${VMNAME}_${dbname}.$(date +%u).tar.gz"
    (( $? != 0 )) && ret=1
    popd >/dev/null
    rm -rf dump
  done
  popd > /dev/null
  rm -rf /tmp/dump
  return $ret
}

# update website asset folder from archive file
assetsarchive() {
  local ret=0
  local archivefile=''
  local destfolder="$1"

  # prepare tmp folder
  rm -rf /tmp/assets
  mkdir /tmp/assets

  pushd /tmp/assets > /dev/null
  if (( $? == 0 )); then
    rsync -av --exclude config_* --exclude css --exclude js --exclude styles --exclude php ${destfolder}/ .
    rm -f assets*tar.gz
    tar cvfz ${VMNAME}_${PATHURI}_assets.$(date +%u).tar.gz *
    if (( $? == 0 )); then
      ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST backup/ "${VMNAME}_${PATHURI}_assets.$(date +%u).tar.gz"
    else
      ret=1
    fi
  else
    ret=1
  fi
  popd > /dev/null
  rm -rf /tmp/assets
  return $ret
}

# send current commit
tagcommit() {
  pushd "${DOCROOT}" > /dev/null
  git rev-parse HEAD > /tmp/${VMNAME}_${PATHURI}.$(date +%u).hash
  ncftpput -S .tmp -u $FTPUSER -p $FTPPASSWD $FTPHOST backup/ /tmp/${VMNAME}_${PATHURI}.$(date +%u).hash
  popd > /dev/null
}

case "$FRAMEWORK" in
  "drupal"*)
    postdrupal
    ;;
  "symfony"*)
    postsymfony2
    ;;
  "wordpress")
    postwordpress
    ;;
  *)
    poststatic
    ;;
esac

tagcommit
