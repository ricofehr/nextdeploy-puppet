# == Class: pm::varnish
#
# Install and configure varnish
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::varnish {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  $v = hiera('varnish_version')
  $auth = hiera('varnish_auth', '')
  $is_auth = hiera("is_auth", "no")

  package { 'varnish':
    ensure => present,
  }
  ->
  file { '/lib/systemd/system/varnish.service':
    ensure => file,
    mode   => 644,
    source => 'puppet:///modules/pm/varnish/varnish.service'
  }
  ->
  file { '/etc/default/varnish':
    ensure => file,
    mode   => 644,
    source => 'puppet:///modules/pm/varnish/varnish_default'
  }
  ->
  file { '/etc/varnish/default.vcl':
    ensure => file,
    mode   => 644,
    source => [
      "puppet:///modules/profiles/varnish/default.vcl.$fqdn",
      "puppet:///modules/pm/varnish/default.vcl.${v}",
      "puppet:///modules/pm/varnish/default.vcl",
    ]
  }
  
  if $is_auth == "yes" {
    exec { 'authbasic':
      command => "/bin/sed -i 's,###AUTH###,,;s,%%BASICAUTH%%,${auth},' /etc/varnish/default.vcl",
      require => File['/etc/varnish/default.vcl'],
      before => Exec['statusok2']
    }
  }

  exec { 'statusok2':
    command => 'sed -i "s;###STATUSOK;;" /etc/varnish/default.vcl',
    user => 'root',
    onlyif => 'test -f /home/modem/.postinstall'
  }
  ->
  file { '/etc/varnish/devicedetect.vcl':
    ensure => file,
    mode   => 644,
    source => [
      "puppet:///modules/pm/varnish/devicedetect.vcl",
    ]
  }
  ->
  service { 'varnish':
    ensure     => running,
    enable     => true,
  }
  ->
  exec { 'systemctl-reload':
    command => 'systemctl daemon-reload',
    onlyif => 'test -f /lib/systemd/system/varnish.service && test -f /bin/systemctl'
  }
  ->
  exec { 'restartvarnish':
    command => 'service varnish restart',
    unless => 'ps aux | grep varnish | grep "-a :80" | grep -v grep',
  }

  file { '/etc/default/varnishncsa':
    ensure => file,
    mode   => 644,
    source => [
      "puppet:///modules/pm/varnish/varnishncsa_default",
    ]
  }
  ->
  service { 'varnishncsa':
    ensure     => running,
    enable     => true,
    subscribe  => File['/etc/default/varnishncsa'],
    require    => Package['varnish']
  }

}
