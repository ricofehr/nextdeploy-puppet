# == Class: pm::base::apt
#
# Ensure that we make apt-update before installing packages
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::base::apt {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    unless => 'test -f /home/modem/.touchaptupdate'
  }

  include apt

  exec { "apt-update":
    command => "apt-get update",
    timeout => 1800
  } ->
  exec { "touchaptupdate":
    command => 'touch /home/modem/.touchaptupdate',
  }
}


# == Class: pm::base
#
# Install some common packages and make some standard settings
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::base {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  $email = hiera('email', 'user@example.com')

  #list of pkgs
  package { [
        'gpgv',
        'vim',
        'htop',
        'dstat',
        'iotop',
        'strace',
        'rsync',
        'ifstat',
        'links',
        'git-core',
        'ethtool',
        'wget',
        'postfix',
        'mailutils',
        'ncftp',
        'curl'
        ]:
        ensure => installed,
  }

  #env locals settings
  file { '/etc/environment':
    ensure => file,
    content => "LANGUAGE=en_US.UTF-8
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8",
  }

  #disable ipv6
  sysctl::value { "net.ipv6.conf.all.disable_ipv6": value => "1"}
  sysctl::value { "net.ipv6.conf.default.disable_ipv6": value => "1"}
  sysctl::value { "net.ipv6.conf.lo.disable_ipv6": value => "1"}

  #avoid swap use
  sysctl::value { "vm.swappiness": value => "0"}
  #tcp tuning
  sysctl::value { "net.ipv4.tcp_max_syn_backlog": value => "8192"}
  sysctl::value { "net.core.somaxconn": value => "2048"}
  sysctl::value { "net.ipv4.tcp_syncookies": value => "1"}

  #ntp class
  include ntp

  user { 'modem':
    name => 'modem',
    ensure => 'present',
    gid => 'www-data',
    home => '/home/modem',
    managehome => 'true',
    password => sha1('modem'),
    shell => '/bin/bash'
  }
  ->
  # Ensure the .ssh directory exists with the right permissions
  file { "/home/modem/.ssh":
    ensure            =>  directory,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0700',
  }
  ->
  # Ensure the .ssh directory exists with the right permissions
  file { "/home/modem/.ssh/id_rsa":
    ensure            =>  file,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0600',
    source => "puppet:///modules/pm/sshkeys/${email}"
  }
  ->
  # Ensure the .ssh directory exists with the right permissions
  file { "/home/modem/.ssh/id_rsa.pub":
    ensure            =>  file,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0644',
    source => "puppet:///modules/pm/sshkeys/${email}.pub"
  }
  ->
  # Ensure the .ssh directory exists with the right permissions
  file { "/home/modem/.ssh/authorized_keys":
    ensure            =>  file,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0600',
    source => "puppet:///modules/pm/sshkeys/${email}.authorized_keys"
  } ->
  # disable root login and password auth
  class { 'ssh::server':
    storeconfigs_enabled => false,
    options => {
      'AllowUsers' => ['modem'],
      'X11Forwarding' => 'no',
      'PasswordAuthentication' => 'no',
      'PermitRootLogin'        => 'no',
      'Port'                   => [22],
    },
  } ->
  # config git username and email
  exec { 'gitconfigemail':
    command => "git config --global user.email ${email}",
    environment => ["HOME=/home/modem"],
    creates => '/home/modem/.gitconfig',
    require => Package['git-core'],
    user => 'modem',
    cwd => '/home/modem'
  }
}
