# == Class: pm::sql
#
# Install mysql with help of official module
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::sql {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    unless => 'test -f /root/.sqlrestart'
  }

  #mysql setting
  class { '::mysql::server':
   notify => Exec['restart-mysql'],
  }

  exec {'restart-mysql':
    command => 'service mysql restart',
    before => Exec['importsh']
  }
  ->
  exec { 'touchsqlrestart':
    command => 'touch /root/.sqlrestart'
  }
  ->
  class { 'pm::monitor::collect::mysql': }

  create_resources ('mysql::db', hiera('mysql_db', []))

}
