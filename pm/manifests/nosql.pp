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

  #apt key server for 3.2
  exec { 'aptkeymongo3.2':
    command => 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927',
    onlyif => 'test -d /etc/apt && ! test -f /usr/bin/mongod'
  } ->

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
    ensure => installed
  }
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