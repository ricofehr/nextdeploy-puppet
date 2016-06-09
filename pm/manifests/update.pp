# == Class: pm::deploy::update
#
# Update vhost documentroot
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::update {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ]
  }

  $docroot = hiera('docrootgit', '/var/www/html')

  exec { 'recordcommit':
    command => 'git rev-parse HEAD > /tmp/commithash1',
    user => 'modem',
    cwd => "${docroot}"
  } ->

  exec { 'gitresetci':
    command => "git reset --hard HEAD",
    user => 'modem',
    cwd => "${docroot}"
  } ->

  exec { 'gitpull':
    command => "git pull --rebase",
    user => 'modem',
    cwd => "${docroot}"
  } ->

  exec { 'recordcommit2':
    command => 'git rev-parse HEAD > /tmp/commithash2',
    user => 'modem',
    cwd => "${docroot}"
  }

  $uris_params = hiera('uris')
  create_resources("pm::build", $uris_params, { require => Exec['recordcommit2'], before => Exec['deletecommithashs'] })

  exec { 'deletecommithashs':
    command => 'rm -f /tmp/commithash1 /tmp/commithash2',
    user => 'modem',
    cwd => "${docroot}"
  }
}