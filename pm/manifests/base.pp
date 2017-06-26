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
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ]
  }

  include apt

  # execute apt-update once 3 hours
  exec { "apt-update":
    command => "apt-get update",
    timeout => 1800,
    onlyif => 'test ! -f /tmp/puppethour || test "$(($(date +%l)%3))" = "0"',
    unless => 'test -f /tmp/puppethour && test "$(date +%l)" = "$(cat /tmp/puppethour)"'
  } ->

  exec { "puppethour":
    command => 'echo "$(date +%l)" > /tmp/puppethour'
  }
}

# == Class: pm::base::fw
#
# Install firewall script for current node
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::base::fw {
  $project = hiera('project', '')

  file { '/etc/init.d/firewall':
    owner => 'root',
    mode => '700',
    source => [
          "puppet:///modules/pm/fw/projects/fw_${project}",
          "puppet:///modules/pm/fw/fw",
          ],
    group => 'root',
    notify => Exec['fw_notify']
  }

  exec { 'fw_notify':
    command => '/etc/init.d/firewall restart',
    path => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true
  }

  exec { 'fw_restart':
    command => '/etc/init.d/firewall restart',
    path => '/usr/bin:/usr/sbin:/bin:/sbin',
    unless => '/sbin/iptables-save | grep "dport 8140"',
    require => File['/etc/init.d/firewall']
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

  #ensure console-data is present for debian
  if $::operatingsystem == 'Debian' {
    package { 'console-data':
      ensure => installed
    }
  }

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
        'mailutils',
        'ncftp'
        ]:
        ensure => installed,
	require => Exec['apt-update']
  }

  # ensure this packages are installed (ignore if they are already defined)
  ensure_packages(['unzip', 'wget', 'ruby-dev', 'nmap', 'curl'])

  package { 'wkhtmltopdf':
    ensure => 'purged'
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

  class { 'pm::base::fw': }

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
    source => [
      "puppet:///modules/pm/sshkeys/vms/${vm_name}.authorized_keys",
      "puppet:///modules/pm/sshkeys/${email}.authorized_keys"
      ]
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
    unless => "grep ${email} /home/modem/.gitconfig",
    require => Package['git-core'],
    user => 'modem',
    cwd => '/home/modem'
  } ->

  exec { 'gitconfigusername':
    command => "git config --global user.name nduser",
    environment => ["HOME=/home/modem"],
    unless => "grep nduser /home/modem/.gitconfig",
    require => Package['git-core'],
    user => 'modem',
    cwd => '/home/modem'
  } ->

  # ensure no-root can cahnge locale
  file_line { 'sudo_rule_loadkeys':
    path => '/etc/sudoers',
    line => 'modem ALL=(ALL) NOPASSWD: /bin/loadkeys',
  } ->

  # ensure no-root can execute global gem
  file_line { 'sudo_rule_gem':
    path => '/etc/sudoers',
    line => 'modem ALL=(ALL) NOPASSWD: /usr/bin/gem',
  } ->

  # ensure modem user can launch puppet update
  file_line { 'sudo_puppet_agent':
    path => '/etc/sudoers',
    line => 'Cmnd_Alias PUPPETAGENT = /usr/bin/puppet agent -t',
  } ->

  # ensure modem user can launch puppet update
  file_line { 'sudo_puppet_agent2':
    path => '/etc/sudoers',
    line => 'modem ALL=(ALL) NOPASSWD: PUPPETAGENT',
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
    command => "test ${nextdeployuri} = nextdeploy.local || curl -X PUT -k -s https://api.${nextdeployuri}/api/v1/vms/${vm_name}/resetpassword/${modempasswd} >/dev/null 2>&1"
  }
}
