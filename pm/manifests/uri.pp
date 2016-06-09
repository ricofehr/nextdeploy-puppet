define pm::uri(
  $absolute = $name,
  $path,
  $envvars = [],
  $aliases = [],
  $framework,
  $rewrites = '',
  $publicfolder = '',
  $customvhost = ''
) {

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  $ismysql = hiera('ismysql', 0)
  $isprod = hiera('isprod', 0)
  $ftpuser = hiera('ftpuser', 'nextdeploy')
  $ftppasswd = hiera('ftppasswd', 'nextdeploy')
  $ismongo = hiera('ismongo', 0)
  $isbackup = hiera('isbackup', 0)
  $vmname = hiera('name', '')
  $override = hiera('override', 'None')
  $project = hiera('project', '')

  file { "${docroot}":
    ensure => directory,
    owner => 'modem',
    group => 'www-data'
  } ->

  exec { "npmsh-${path}":
    command => "npm.sh ${docroot} >/home/modem/lognpm 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    creates => "/home/modem/.deploy${path}",
    timeout => 1800,
    require => Exec['touchdeploygit']
  } ->

  exec { "composersh-${path}":
    command => "composer.sh ${docroot} >/home/modem/logcomposer 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    creates => "/home/modem/.deploy${path}",
    timeout => 1800
  } ->

  exec { "mvnsh-${path}":
    command => "mvn.sh ${docroot} >/home/modem/logmvn 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 7200,
    creates => "/home/modem/.deploy${path}",
    onlyif => 'test -f /usr/bin/mvn'
  }

  if $ismysql == 1 {
    mysql::db { "${path}":
      user => 's_bdd',
      password => 's_bdd',
      host => 'localhost',
      grant => 'all'
    }
  }

  case $framework {
    'drupal6', 'drupal7', 'drupal8', 'symfony2', 'symfony3', 'wordpress-4.5.2', 'static': {
      if $isprod == 1 {
        apache::vhost { "${name}":
            vhost_name => "${name}",
            port => '8080',
            ip => '127.0.0.1',
            override => ["${override}"],
            options => ['FollowSymLinks'],
            serveraliases => $aliases,
            ensure => present,
            docroot_owner => 'modem',
            docroot_group => 'www-data',
            docroot => "${docroot}/${publicfolder}",
            directories => [ { path => "${docroot}/${publicfolder}",
                               allow_override => ["${override}"],
                               custom_fragment => "${rewrites}", options => ['FollowSymLinks'] } ],
            require => [
              File['/etc/apache2/conf.d/tt.conf'],
              Exec['touchdeploygit']
            ],
            custom_fragment => "${customvhost}",
            before => Service['varnish']
          }
      }
      else {
        apache::vhost { "${name}":
            vhost_name => "${name}",
            port => '8080',
            ip => '127.0.0.1',
            override => ["${override}"],
            options => ['Indexes', 'FollowSymLinks'],
            serveraliases => $aliases,
            aliases => [
              { alias => '/robots.txt', path => '/var/www/robots.txt' }
            ],
            ensure => present,
            docroot_owner => 'modem',
            docroot_group => 'www-data',
            docroot => "${docroot}/${publicfolder}",
            directories => [ { path => "${docroot}/${publicfolder}",
                               allow_override => ["${override}"],
                               custom_fragment => "${rewrites}", options => ['Indexes', 'FollowSymLinks'] } ],
            require => [
              File['/etc/apache2/conf.d/tt.conf'],
              Exec['touchdeploygit']
            ],
            custom_fragment => "${custom_vhost}",
            before => Service['varnish']
          }
      }
    }
  }

  case $framework {
      'symfony2': {
        if $ismysql == 1 {
          pm::uri::symfony { "${project}${path}":
            version => 2,
            path => "${path}",
            absolute => "${absolute}",
            require => [ Exec["composersh-${path}"], Exec["npmsh-${path}"], Mysql::Db["${path}"] ],
            before => [ Exec["importsh-${path}"] ]
          }
        }
        else {
          pm::uri::symfony { "${project}${path}":
            version => 2,
            path => "${path}",
            absolute => "${absolute}",
            require => [ Exec["composersh-${path}"], Exec["npmsh-${path}"] ],
            before => [ Exec["importsh-${path}"] ]
          }
        }
      }

      'symfony3': {
        if $ismysql == 1 {
          pm::uri::symfony { "${project}${path}":
            version => 3,
            path => "${path}",
            require => [ Exec["composersh-${path}"], Exec["npmsh-${path}"], Mysql::Db["${path}"] ],
            before => [ Exec["importsh-${path}"] ]
          }
        }
        else {
          pm::uri::symfony { "${project}${path}":
            version => 3,
            path => "${path}",
            require => [ Exec["composersh-${path}"], Exec["npmsh-${path}"] ],
            before => [ Exec["importsh-${path}"] ]
          }
        }
      }

      'drupal6': {
        pm::uri::drupal { "${project}${path}":
          version => 6,
          path => "${path}",
          require => [ Exec["composersh-${path}"], Exec["npmsh-${path}"], Mysql::Db["${path}"] ],
          before => [ Exec["importsh-${path}"] ]
        }
      }

      'drupal7': {
        pm::uri::drupal { "${project}${path}":
          version => 7,
          path => "${path}",
          require => [ Exec["composersh-${path}"], Exec["npmsh-${path}"], Mysql::Db["${path}"] ],
          before => [ Exec["importsh-${path}"] ]
        }
      }

      'drupal8': {
        pm::uri::drupal { "${project}${path}":
          version => 8,
          path => "${path}",
          require => [ Exec["composersh-${path}"], Exec["npmsh-${path}"], Mysql::Db["${path}"] ],
          before => [ Exec["importsh-${path}"] ]
        }
      }

      'nodejs': {
        pm::uri::nodejs { "${project}${path}":
          path => "${path}",
          envvars => $envvars,
          require => [ Exec["npmsh-${path}"] ],
          before => [ Exec["importsh-${path}"] ]
        }
      }

      'reactjs': {
        pm::uri::reactjs { "${project}${path}":
          path => "${path}",
          envvars => $envvars,
          require => [ Exec["npmsh-${path}"] ],
          before => [ Exec["importsh-${path}"] ]
        }
      }

      'wordpress-4.5.2': {
        pm::uri::wordpress { "${project}${path}":
          path => "${path}",
          absolute => "${absolute}",
          version => '4.5.2',
          require => [ Exec["composersh-${path}"], Exec["npmsh-${path}"], Mysql::Db["${path}"] ],
          before => [ Exec["importsh-${path}"] ]
        }
      }

  }

  exec { "importsh-${path}":
    command => "import.sh --uri ${absolute} --path ${path} --framework ${framework} --ftpuser ${ftpuser} --ftppasswd ${ftppasswd} --ismysql ${ismysql} --ismongo ${ismongo} >>/home/modem/import.log 2>&1",
    timeout => 14400,
    cwd => "${docrootgit}",
    user => 'modem',
    group => 'www-data',
    creates => "/home/modem/.deploy${path}",
    require => File['/usr/local/bin/import.sh']
  } ->

  exec { "touchdeploy-${path}":
    command => "touch /home/modem/.deploy${path}",
    user => 'modem',
    group => 'www-data',
    creates => "/home/modem/.deploy${path}"
  }

  if $isbackup == 1 {
    exec { "backupsh-${path}":
      command => "backup.sh --uri ${absolute} --path ${path} --framework ${framework} --ftpuser ${ftpuser} --ftppasswd ${ftppasswd} --ismysql ${ismysql} --ismongo ${ismongo} --vmname ${vmname} >>/home/modem/backup.log 2>&1",
      timeout => 14400,
      cwd => "${docrootgit}",
      user => 'modem',
      group => 'www-data',
      unless => 'test -f /tmp/backupday && test "$(date +%u)" = "$(cat /tmp/backupday)"',
      require => [ File['/usr/local/bin/backup.sh'], Exec["importsh-${path}"] ]
    } ->

    exec { "lockbackup-${path}":
      command => "date +%u > /tmp/backupday",
      unless => 'test -f /tmp/backupday && test "$(date +%u)" = "$(cat /tmp/backupday)"',
      before => Exec["touchdeploy-${path}"]
    }
  }
}


define pm::uri::drupal(
  $version = 7,
  $path,
) {

  $project = hiera('project', 'currentproject')
  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"
  $email = hiera('email', 'test@yopmail.com')
  $username = hiera('httpuser', 'admin')
  $adminpass = hiera('httppasswd', 'nextdeploy')
  $iscache = hiera('iscache', '0')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data'
  }

  exec { "resetopcache-${path}":
    command => "php -r 'opcache_reset();'",
    user => 'root',
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}",
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  } ->

  exec { "sleepopcache-${path}":
    command => "sleep 10",
    creates => "/home/modem/.deploy${path}"
  } ->

  exec { "getdrush-${path}":
    command => 'wget http://files.drush.org/drush.phar',
    creates => '/usr/local/bin/drush',
    cwd => '/tmp'
  } ->

  exec { "chmodrush-${path}":
    command => 'chmod +x drush.phar',
    creates => '/usr/local/bin/drush',
    cwd => '/tmp'
  } ->

  exec { "mvdrush-${path}":
    command => 'mv drush.phar /usr/local/bin/drush',
    creates => '/usr/local/bin/drush',
    user => 'root',
    cwd => '/tmp'
  } ->

  exec { "site-install-${path}":
    command => "/usr/local/bin/drush -y site-install --db-url=mysql://s_bdd:s_bdd@localhost:3306/${path} --locale=en --account-name=${username} --account-pass=${adminpass} --site-name=${project} --account-mail=${email} --site-mail=${email} standard >/dev/null 2>&1",
    environment => ["HOME=/home/modem", "USER=modem", "LC_ALL=en_US.UTF-8", "LANG=en_US.UTF-8", "LANGUAGE=en_US.UTF-8", "SHELL=/bin/bash", "TERM=xterm"],
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}",
    timeout => 3600
  }

  if $iscache == 1 {
    case $version {
      6: {
        exec { "memcachesettingsd6-${path}":
          command => 'echo  "\$conf[\'cache_inc\'] = \'./sites/all/modules/memcache/memcache.inc\';\$conf[\'memcache_bins\'] = array(\'cache\' => \'default\', \'cache_form\' => \'database\');" >> sites/default/settings.php',
          user => 'root',
          creates => "/home/modem/.deploy${path}",
          cwd => "${docroot}",
          require => Exec['site-install'],
          before => Exec["touchdeploy-${path}"]
        }
      }
      7: {
        exec { "memcachesettingsd7-${path}":
          command => 'echo  "\$conf[\'cache_backends\'][] = \'./sites/all/modules/memcache/memcache.inc\';\$conf[\'cache_default_class\'] = \'MemCacheDrupal\';\$conf[\'cache_class_cache_form\'] = \'DrupalDatabaseCache\';" >> sites/default/settings.php',
          user => 'root',
          creates => "/home/modem/.deploy${path}",
          cwd => "${docroot}",
          require => Exec['site-install'],
          before => Exec["touchdeploy-${path}"]
        }
      }
      8: {
        exec { "memcachesettingsd8-${path}":
          command => 'drush -y pm-enable memcache >/dev/null 2>&1',
          environment => ["HOME=/home/modem", "USER=modem", "LC_ALL=en_US.UTF-8", "LANG=en_US.UTF-8", "LANGUAGE=en_US.UTF-8", "SHELL=/bin/bash", "TERM=xterm"],
          creates => "/home/modem/.deploy${path}",
          cwd => "${docroot}",
          require => Exec["site-install-${path}"]
        } ->

        exec { "drush-cr-${path}":
          command => "/usr/local/bin/drush cr >/dev/null 2>&1",
          environment => ["HOME=/home/modem", "USER=modem", "LC_ALL=en_US.UTF-8", "LANG=en_US.UTF-8", "LANGUAGE=en_US.UTF-8", "SHELL=/bin/bash", "TERM=xterm"],
          timeout => 100,
          creates => "/home/modem/.deploy${path}",
          cwd => "${docroot}",
          before => Exec["touchdeploy-${path}"]
        }
      }
    }
  }
}

define pm::uri::symfony(
  $version = 2,
  $path = "server",
  $absolute
) {

  $webenv = hiera('webenv', 'dev')
  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  case "$version" {
    2: { $consolebin = "app/console" }
    3: { $consolebin = "bin/console" }
  }

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    environment => ["HOME=/home/modem"],
    timeout => 1800
  }

  # Ensure the logs/cache directory exists with the right permissions
  file { "${docroot}/app/logs":
    ensure            =>  directory,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0770'
  } ->

  # Ensure the logs/cache directory exists with the right permissions
  file { "${docroot}/app/cache":
    ensure            =>  directory,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0770'
  } ->

  exec { "parameters_dbname-${path}":
    command => "sed -i 's,database_name:.*$,database_name: ${path},' app/config/parameters.yml",
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}",
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  } ->

  exec { "parameters_dbuser-${path}":
    command => 'sed -i "s,database_user:.*$,database_user: s_bdd," app/config/parameters.yml',
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "parameters_dbpasswd-${path}":
    command => 'sed -i "s,database_password:.*$,database_password: s_bdd," app/config/parameters.yml',
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "parameters_mongoserver-${path}":
    command => 'sed -i "s,mongodb_server:.*$,mongodb_server: mongodb://localhost:27017," app/config/parameters.yml',
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "parameters_mongoname-${path}":
    command => 'sed -i "s,mongodb_default_name:.*$,mongodb_default_name: mongodb," app/config/parameters.yml',
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "parameters_basedomain-${path}":
    command => "sed -i 's,base_domain:.*$,base_domain: ${absolute},' app/config/parameters.yml",
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "rmcachedev-${path}":
    command => 'rm -rf app/cache/dev',
    onlyif => 'test -d app/cache/dev',
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "rmcacheprod-${path}":
    command => 'rm -rf app/cache/prod',
    onlyif => 'test -d app/cache/prod',
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "schema-${path}":
    command => "php ${consolebin} doctrine:schema:create --env=${webenv}",
    onlyif => "ps aux | grep mysqld | grep -v grep",
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "assets-${path}":
    command => "php ${consolebin} assets:install --symlink --env=${webenv}",
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "assetic-${path}":
    command => "php ${consolebin} assetic:dump --env=${webenv}",
    onlyif => "php ${consolebin} | grep assetic",
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  }
}


define pm::uri::wordpress(
  $absolute,
  $path = "server",
  $version = '4.5.2'
) {
  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"
  $email = hiera('email', 'test@yopmail.com')
  $commit = hiera('commit', 'HEAD')
  $username = hiera('httpuser', 'admin')
  $adminpass = hiera('httppasswd', 'nextdeploy')
  $project = hiera('project', 'currentproject')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    environment => ["HOME=/home/modem"],
    timeout => 1800
  }

  exec { "wp-cli1-${path}":
    command => 'curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar',
    cwd => '/tmp',
    creates => "/home/modem/.deploy${path}",
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  } ->

  exec { "wp-cli2-${path}":
    command => 'chmod +x /tmp/wp-cli.phar',
    creates => "/home/modem/.deploy${path}"
  } ->

  exec { "wp-cli3-${path}":
    command => 'mv /tmp/wp-cli.phar /usr/local/bin/wp',
    user => 'root',
    creates => "/home/modem/.deploy${path}"
  } ->

  exec { "dlwp-${path}":
    command => "wp core download --version=${version}",
    unless => 'test -d wp-admin',
    cwd => "${docroot}",
    creates => "/home/modem/.deploy${path}"
  } ->

  exec { "configwp-${path}":
    command => "wp core config --dbname=${path} --dbuser=s_bdd --dbpass=s_bdd",
    cwd => "${docroot}",
    creates => "${docroot}/wp-config.php"
  } ->

  exec { "gitresetwp-${path}":
    command => "git reset --hard ${commit}",
    user => 'modem',
    cwd => "${docroot}",
    group => 'www-data',
    creates => "/home/modem/.deploy${path}"
  } ->

  exec { "installbdd-${path}":
    command => "wp core install --url=${absolute} --title=${projectname} --admin_user=${username} --admin_password=${adminpass} --admin_email=${email}",
    cwd => "${docroot}",
    creates => "/home/modem/.deploy${path}"
  }
}


define pm::uri::nodejs(
  $path = "nodejs",
  $envvars = ["HOME=/home/modem", "PORT=3100"]
) {

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    timeout => 1800
  }

  exec { "pm2start-${path}":
    command => "pm2 start -f app.js --name '${path}-app'",
    onlyif => 'test -f app.js',
    environment => $envvars,
    cwd => "${docroot}",
    require => [ Package['pm2'], Exec['touchdeploygit'] ],
    unless => "test -f /home/modem/.pm2/pids/${path}-app-*.pid"
  } ->

  exec { "pm2start_server-${path}":
    command => "pm2 start -f server.js --name '${path}-server'",
    onlyif => 'test -f server.js',
    environment => $envvars,
    cwd => "${docroot}",
    unless => "test -f /home/modem/.pm2/pids/${path}-server-*.pid"
  }
}

define pm::uri::reactjs(
  $path = "nodejs",
  $envvars = ["HOME=/home/modem", "PORT=3100"]
) {

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    timeout => 1800
  }

  exec { "pm2start_server_bin-${path}":
    command => "pm2 start -f bin/server.js --name '${path}-server'",
    onlyif => 'test -f bin/server.js',
    environment => $envvars,
    cwd => "${docroot}",
    require => [ Package['pm2'], Exec['touchdeploygit'] ],
    unless => "test -f /home/modem/.pm2/pids/${path}-server-*.pid"
  } ->

  # reactjs start
  exec { "pm2start_api_bin-${path}":
    command => "pm2 start -f bin/api.js --name '${path}-api'",
    environment => $envvars,
    cwd => "${docroot}",
    onlyif => 'test -f bin/api.js',
    unless => "test -f /home/modem/.pm2/pids/${path}-api-*.pid"
  }
}



