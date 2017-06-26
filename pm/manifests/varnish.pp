# == Class: pm::varnish
#
# Install and configure varnish
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::varnish(
  $backends = [],
  $staticttl = '1h',
  $version = 3,
  $isauth = true,
  $iscached = false,
  $isprod = false,
  $iscors = true,
  $isoffline = false,
  $basicauth = 'b2tvazpva29r') {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  $project = hiera('project', 'www.test.com')
  $offlineuri = hiera('offlineuri', 'maintenance.nextdeploy.local')

  package { 'varnish':
    ensure => present,
  } ->

  file { '/lib/systemd/system/varnish.service':
    ensure => file,
    mode   => 644,
    source => "puppet:///modules/pm/varnish/varnish.service.${version}",
    owner => 'root'
  } ->

  file { '/etc/default/varnish':
    ensure => file,
    mode   => 644,
    source => "puppet:///modules/pm/varnish/varnish_default.${version}",
    owner => 'root'
  } ->

  # Template uses:
  # - $backends
  # - $staticttl
  # - $isauth
  # - $iscached
  # - $isprod
  # - $iscors
  # - $basicauth
  # - $isoffline
  # - $offlineuri
  file { '/etc/varnish/default.vcl':
    ensure => file,
    mode   => 644,
    content => multitemplate("pm/varnish/projects/${project}/default.vcl.${version}.erb",
                             "pm/varnish/default.vcl.${version}.erb"),
    owner => 'root',
    notify => Service['varnish']
  } ->

  service { 'varnish':
    ensure     => running,
    enable     => true,
  } ->
  # ugly condition (check if varnish is listening on port 80)
  exec { 'systemctl-reload':
    command => 'systemctl daemon-reload',
    onlyif => 'test -f /lib/systemd/system/varnish.service && test -f /bin/systemctl',
    unless => 'ps aux | grep varnish | grep "a :80" | grep -v grep'
  }
  ->
  # ugly condition (check if varnish is listening on port 80)
  exec { 'restartvarnish':
    command => 'service varnish restart',
    unless => 'ps aux | grep varnish | grep "a :80" | grep -v grep',
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
  ->
  class { 'pm::monitor::collect::varnish': }

  # stop varnishlog if already started
  exec { 'stopvarnishlog':
    command => 'service varnishlog stop',
    onlyif => 'test -f /lib/systemd/system/varnishlog.service',
  } ->

  file { '/etc/default/varnishlog':
    ensure => file,
    mode   => 644,
    source => [
      "puppet:///modules/pm/varnish/varnishlog_default",
    ]
  }
  ->

  file { '/lib/systemd/system/varnishlog.service':
    ensure => absent
  }
}
