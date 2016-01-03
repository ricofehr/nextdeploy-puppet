# == Class: pm::elastic
#
# Install elasticsearch with help of official modules
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::elastic {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.esrun',
    environment => ["HOME=/home/modem"]
  }

  exec { 'aptsource':
    command => 'echo "deb http://packages.elastic.co/elasticsearch/1.4/debian stable main" > /etc/apt/sources.list.d/elastic.list',
    user => 'root'
  } ->

  exec { 'aptkey':
    command => 'wget -q -O - http://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -',
    require => Package['wget'],
    user => 'root'
  } ->

  exec { 'elasticaptupd':
    command => 'apt-get update',
    user => 'root'
  } ->

  # elastic setting
  # avoid use official module because too many issues
  #class { 'elasticsearch':
  #  repo_version => '1.4',
  #  ensure => 'present',
  #  java_install => true
  #} ->

  package { 'elasticsearch':
    ensure => 'present'
  } ->

  exec { 'defaultes':
    command => 'sed -i "s;#START_DAEMON=true;START_DAEMON=true;" /etc/default/elasticsearch',
    onlyif => 'test -f /etc/default/elasticsearch',
    user => 'root'
  } ->

  exec { 'reastartes':
    command => 'service elasticsearch restart',
    onlyif => 'test -f /etc/default/elasticsearch',
    user => 'root'
  } ->

  exec { 'touches':
    command => 'touch /home/modem/.esrun'
  } ->

  service { 'elasticsearch':
    ensure => 'running',
    enable     => true
  }
}