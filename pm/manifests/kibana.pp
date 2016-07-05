# == Class: pm::kibana
#
# Install kibana with help of leseaux module
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::kibana {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ]
  }

  include kibana4

  exec { 'kibana-aptupdate':
    command => "/usr/bin/apt-get update",
    timeout => 1800,
    user => 'root',
    creates => '/opt/kibana/bin/kibana',
    onlyif => 'test -d /etc/apt'
  }

  Apt::Source <| |> ~> Exec['kibana-aptupdate'] -> Package['kibana']
}