# == Class: pm::mail
#
# Install mail service and apply custom setting
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::mail {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    creates => '/root/.installpostfix'
  }

  $vm_name = hiera('name', 'undefined')
  $nextdeployuri = hiera('nextdeployuri', 'nextdeploy.local')

  package { 'postfix':
    ensure => present,
  } ->

  file { '/etc/postfix/canonical':
    ensure => file,
    mode   => 644,
    content => "@${vm_name} @${nextdeployuri}
www-data www-data@${nextdeployuri}
modem modem@${nextdeployuri}
root root@${nextdeployuri}",
    owner => 'root'
  } ->

  file_line { 'addlinecanonical':
    path => '/etc/postfix/main.cf',
    line => 'sender_canonical_maps = hash:/etc/postfix/canonical'
  } ->

  exec { 'postmapcanonical':
    command => 'postmap canonical',
    cwd => '/etc/postfix'
  } ->

  exec { 'restartpostfix':
    command => 'service postfix restart',
    cwd => '/etc/postfix'
  } ->

  exec { 'touchpostfix':
    command => 'touch /root/.installpostfix'
  } ->

  service { 'postfix':
    ensure     => running,
    enable     => true,
  }
}
