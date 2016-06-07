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
   root_password => '8to9or1',
   notify => Exec['restart-mysql'],
  }

  exec {'restart-mysql':
    command => 'service mysql restart',
    before => File['/usr/local/bin/import.sh']
  }
  ->
  exec { 'touchsqlrestart':
    command => 'touch /root/.sqlrestart'
  }
  ->
  class { 'pm::monitor::collect::mysql': }

}