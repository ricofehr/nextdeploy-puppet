# == Class: pm::sql
#
# Install mysql with help of official module
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
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
    command => 'service mysql restart'
  }
  ->
  exec { 'touchsqlrestart':
    command => 'touch /root/.sqlrestart'
  }

  create_resources ('mysql::db', hiera('mysql_db', []))
}
