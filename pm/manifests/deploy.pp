# == Class: pm::deploy::vhost
#
# Create the documentroot and clone the git repository
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::vhost {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ]
  }

  $docroot = hiera('docrootgit', '/var/www/html')
  $gitpath = hiera('gitpath', '')
  $vmname = hiera('name', 'ndproject')
  $branch = hiera('branch', 'master')
  $commit = hiera('commit', 'HEAD')
  $toolsuri = hiera('toolsuri', 'pmtools.nextdeploy.local')
  $isweb = hiera('iswebserver', 0)

  exec { 'nohostvalidation':
    command => 'echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config',
    creates => '/home/modem/.deploygit',
    user => 'root'
  } ->

  exec { 'mkdir_docroot':
    command => "mkdir -p ${docroot}",
    creates => '/home/modem/.deploygit',
    user => 'root'
  } ->

  exec { 'chown_varwww':
    command => "chown -R modem:www-data ${docroot}",
    creates => '/home/modem/.deploygit',
    user => 'root'
  } ->

  exec { 'gitclone':
    command => "git clone -b ${branch} ${gitpath} ${docroot}",
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    unless => "test -d ${docroot}/.git",
    require => [ Package['git-core'], File['/home/modem/.ssh/id_rsa'] ]
  } ->

  exec { 'gitreset':
    command => "git reset --hard ${commit}",
    user => 'modem',
    cwd => "${docroot}",
    creates => '/home/modem/.deploygit',
    group => 'www-data'
  } ->

  file { '/usr/local/bin/npm.sh':
    source => 'puppet:///modules/pm/tools/npm.sh',
    owner => 'modem',
    group => 'www-data',
    mode => '0755'
  } ->

  file { '/usr/local/bin/composer.sh':
    source => 'puppet:///modules/pm/tools/composer.sh',
    owner => 'modem',
    group => 'www-data',
    mode => '0755'
  } ->

  file { '/usr/local/bin/mvn.sh':
    source => 'puppet:///modules/pm/tools/mvn.sh',
    owner => 'modem',
    group => 'www-data',
    mode => '0755'
  } ->

  file { '/usr/local/bin/import.sh':
    source => 'puppet:///modules/pm/tools/import.sh',
    owner => 'modem',
    group => 'www-data',
    mode => '0755'
  } ->

  file { '/usr/local/bin/export.sh':
    source => 'puppet:///modules/pm/tools/export.sh',
    owner => 'modem',
    group => 'www-data',
    mode => '0755'
  } ->

  file { '/usr/local/bin/refreshcommit.sh':
    source => 'puppet:///modules/pm/tools/refreshcommit.sh',
    owner => 'modem',
    group => 'www-data',
    mode => '0755'
  } ->

  exec { 'touchdeploygit':
    command => 'touch /home/modem/.deploygit',
    creates => '/home/modem/.deploygit',
    user => 'modem'
  } ->

  samba::server::share {"${vmname}":
    comment              => 'Web Share',
    path                 => "${docroot}",
    writable             => true,
    valid_users          => 'modem',
    browsable            => true,
    create_mask          => 0644,
    directory_mask       => 0755,
    force_directory_mode => 0755,
    force_group          => 'www-data',
    force_user           => 'modem',
    hide_dot_files       => false,
    follow_symlinks      => true,
    printable            => false
  }

  if $isweb == 1 {
    apache::vhost { "${toolsuri}":
      vhost_name => "${toolsuri}",
      port => '8080',
      ip => '127.0.0.1',
      override => ["All"],
      options => ['FollowSymLinks'],

      aliases => [
        { alias => '/robots.txt', path => '/var/www/robots.txt' },
      ],
      ensure => present,
      docroot_owner => 'modem',
      docroot_group => 'www-data',
      docroot => "/var/www/pm_tools",
      directories => [ { path => "/var/www/pm_tools",
                         allow_override => ["All"] } ],
      require => [
        File['/etc/apache2/conf.d/tt.conf'],
        Exec['touchdeploygit']
      ],
      before => Service['varnish']
    }
  }


  $uris_params = hiera('uris')
  create_resources("pm::uri", $uris_params, { require => Exec['touchdeploygit'], before => Exec['hosts_writable'] })
}

# == Class: pm::deploy::postinstall
#
# Some extra tasks to execute after project installation
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::postinstall {
  $docroot = hiera('docrootgit', '/var/www/html')
  $email = hiera('email')
  $nextdeployuri = hiera('nextdeployuri', 'nextdeploy.local')
  $project = hiera('project', '')
  $vm_name = hiera('name', 'undefined')
  $line_host = hiera('etchosts', 'website')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    cwd => "${docroot}",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    timeout => 1800
  }

  exec { 'hosts_writable':
    command => 'chmod 777 /etc/hosts',
    user => 'root',
    creates => '/home/modem/.postinstall',
    require => Exec['touchdeploygit']
  } ->

  exec { 'touch_postinstallsh':
    command => 'touch scripts/postinstall.sh',
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'chmod_postinstallsh':
    command => 'chmod +x scripts/postinstall.sh',
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'postinstall':
    command => "/bin/bash scripts/postinstall.sh ${vm_name}.os.${nextdeployuri} >/home/modem/postinstall.log 2>&1",
    timeout => 7200,
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'touch_cron':
    command => 'touch scripts/crontab',
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'copy_cron':
    command => 'cp scripts/crontab /var/spool/cron/crontabs/modem',
    user => 'root',
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'chown_cron':
    command => 'chown modem: /var/spool/cron/crontabs/modem',
    user => 'root',
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'chmod_cron':
    command => 'chmod 600 /var/spool/cron/crontabs/modem',
    creates => '/home/modem/.postinstall',
    user => 'root'
  } ->

  exec { 'restart_cron':
    command => 'service cron restart',
    creates => '/home/modem/.postinstall',
    user => 'root'
  } ->

  file_line { 'localuris':
    path => '/etc/hosts',
    line => "127.0.1.1 ${line_host}",
  } ->

  exec { 'restartvarnish_postinstall':
    command => 'service varnish restart',
    onlyif => 'test -d /etc/varnish',
    creates => '/home/modem/.postinstall',
    user => 'root'
  } ->

  exec { 'touchstatusok':
    command => 'touch /var/www/status_ok',
    creates => '/home/modem/.postinstall',
    user => 'root'
  } ->

  exec { 'chownstatusok':
    command => 'chown modem: /var/www/status_ok',
    creates => '/home/modem/.postinstall',
    user => 'root'
  } ->

  exec { 'mail_endinstall':
    command => "echo 'Your vm for the project ${project} is installed and ready to work. Connect to your NextDeploy account (https://ui.${nextdeployuri}/) for getting urls and others access.' | mail -s '[NextDeploy] Vm installed' ${email}",
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'curl_setupcomplete':
    command => "curl -X PUT -k -s https://api.${nextdeployuri}/api/v1/vms/${vm_name}/setupcomplete >/dev/null 2>&1",
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'touchpostinstall':
    command => 'touch /home/modem/.postinstall',
    creates => '/home/modem/.postinstall'
  } ->

  exec { 'refreshcommit':
    command => "refreshcommit.sh ${nextdeployuri} ${vm_name}",
    require => File['/usr/local/bin/refreshcommit.sh']
  }
}
