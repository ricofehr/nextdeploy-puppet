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

  $version = hiera('mongodb::globals::version', '3.2.0')

  ensure_packages(['apt-transport-https'])

  #mongo setting
  class {'::mongodb::globals':
    manage_package_repo => true,
    require => Package['apt-transport-https']
  } ->

  class {'::mongodb::server':
    pidfilepath => '/tmp/mongod.pid',
    require => Package['apt-transport-https']
  } ->

  class {'::mongodb::client':
    require => Package['apt-transport-https']
  } ->

  package { 'mongodb_tool':
      ensure => "${version}",
      name   => 'mongodb-org-tools',
      tag    => 'mongodb',
      before => File['/usr/local/bin/import.sh']
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