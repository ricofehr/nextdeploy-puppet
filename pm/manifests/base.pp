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
  $modemlayout = hiera('layout', 'fr')
  $modempasswd = fqdn_rand_string(6, 'ertyuioplkjhgfdsxcvbn', strftime("%s"))
  $modemsaltpasswd = pw_hash("${modempasswd}", 'SHA-512', 'nextdeploy')
  $nextdeployuri = hiera('nextdeployuri', 'nextdeploy.local')
  $vm_name = hiera('name', 'undefined')

  #ensure console-data is absent
  package { 'console-data':
    ensure => purged
  } ->

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

  # samba share
  class {'samba::server':
    workgroup     => 'workgroup',
    server_string => "NextDeploy Samba Share",
    interfaces    => "eth0",
    security      => 'USER'
  }

  user { 'modem':
    name => 'modem',
    ensure => 'present',
    gid => 'www-data',
    home => '/home/modem',
    managehome => 'true',
    shell => '/bin/bash'
  }
  -> 

  # exec usermod instead of User reference beacause weird puppet bug into trusty
  exec { 'changepasswd':
    command => "/usr/sbin/usermod -p '${modemsaltpasswd}' modem"
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
  } ->

  # ensure no-root can cahnge locale
  file_line { 'sudo_rule_loadkeys':
    path => '/etc/sudoers',
    line => 'modem ALL=(ALL) NOPASSWD: /bin/loadkeys',
  } ->

  # change layout at login
  file_line { 'profile_layout':
    path => '/home/modem/.profile',
    line => "sudo loadkeys ${modemlayout}",
  } ->

  file { '/usr/local/bin/resetsambapasswd.sh':
    source => 'puppet:///modules/pm/tools/resetsambapasswd.sh',
    owner => 'root',
    mode => '0700'
  } ->

  exec { 'resetsambapasswd':
    command => "resetsambapasswd.sh ${modempasswd}",
    require => Class['samba::server']
  } ->

  exec { 'curl_resetmodempasswd':
    command => "curl -X PUT -k -s https://api.${nextdeployuri}/api/v1/vms/${vm_name}/resetpassword/${modempasswd} >/dev/null 2>&1"
  }
}
