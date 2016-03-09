# == Class: pm::nosql::mongo
#
# Install mongodb with help of official module
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::nosql::mongo {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ]
  }

  #mongo setting
  class {'::mongodb::globals':
    manage_package_repo => true
  } ->

  class {'::mongodb::server':
    pidfilepath => '/tmp/mongod.pid'
  } ->

  package { [
    'mongodb-org-shell',
    'mongodb-org-tools'
    ]:
    ensure => installed,
    require => Package['mongodb-org-server']
  }

  exec { 'mongo-aptupdate':
    command => "/usr/bin/apt-get update",
    timeout => 1800,
    user => 'root',
    creates => '/usr/bin/mongod',
    onlyif => 'test -d /etc/apt'
  }

  # ensure that apt-update is running before install nodejs package
  Apt::Source <| |> ~> Exec['mongo-aptupdate'] -> Package['mongodb-org-server']
}


# == Class: pm::nosql::memcache
#
# Install mongodb with help of official module
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::nosql::memcache {
  #memcached setting
  class { 'memcached':
    max_memory => 2048,
    tcp_port => '11211',
    udp_port => '11211',
    listen_ip => '127.0.0.1'
  }
}


# == Class: pm::nosql::redis
#
# Install redis with help of official module
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::nosql::redis {
  # redis setting
  class { '::redis': }
  # redis monitoring
  class { 'pm::monitor::collect::redis': }
}