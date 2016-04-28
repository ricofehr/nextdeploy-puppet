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
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    unless => 'test -f /home/modem/.deploygit'
  }

  $docroot = hiera('docrootgit', '/var/www/html')
  $gitpath = hiera('gitpath', '')
  $vmname = hiera('name', 'ndproject')
  $branch = hiera('branch', 'master')
  $commit = hiera('commit', 'HEAD')

  exec { 'nohostvalidation':
    command => 'echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config',
    user => 'root'
  } ->

  exec { 'mkdir_docroot':
    command => "mkdir -p ${docroot}",
    user => 'root'
  } ->

  exec { 'chown_varwww':
    command => "chown -R modem:www-data ${docroot}",
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
}


# == Class: pm::deploy::symfony2
#
# Deploy the symfony2 framework from the documentroot of the project
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::symfony2 {
  $docroot = hiera('docrootgit', '/var/www/html')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.deploysf2',
    cwd => "${docroot}/server",
    environment => ["HOME=/home/modem"],
    timeout => 1800,
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  }

  # Ensure the logs/cache directory exists with the right permissions
  file { "${docroot}/server/app/logs":
    ensure            =>  directory,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0770'
  } ->

  # Ensure the logs/cache directory exists with the right permissions
  file { "${docroot}/server/app/cache":
    ensure            =>  directory,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0770'
  } ->

  exec { 'npmsh':
    command => "npm.sh ${docroot} >/home/modem/lognpm 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800
  } ->

  exec { 'composersh':
    command => "composer.sh ${docroot} >/home/modem/logcomposer 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800
  } ->

  exec { 'parameters_dbname':
    command => 'sed -i "s,database_name:.*$,database_name: s_bdd," app/config/parameters.yml'
  } ->

  exec { 'parameters_dbuser':
    command => 'sed -i "s,database_user:.*$,database_user: s_bdd," app/config/parameters.yml'
  } ->

  exec { 'parameters_dbpasswd':
    command => 'sed -i "s,database_password:.*$,database_password: s_bdd," app/config/parameters.yml'
  } ->

  exec { 'parameters_mongoserver':
    command => 'sed -i "s,mongodb_server:.*$,mongodb_server: mongodb://localhost:27017," app/config/parameters.yml'
  } ->

  exec { 'parameters_mongoname':
    command => 'sed -i "s,mongodb_default_name:.*$,mongodb_default_name: mongodb," app/config/parameters.yml'
  } ->

  exec { 'rmcachedev':
    command => 'rm -rf app/cache/dev',
    onlyif => 'test -d app/cache/dev'
  } ->

  exec { 'rmcacheprod':
    command => 'rm -rf app/cache/prod',
    onlyif => 'test -d app/cache/prod'
  } ->

  exec { 'schema':
    command => 'php app/console doctrine:schema:create',
    onlyif => 'ps aux | grep mysqld | grep -v grep'
  } ->

  exec { 'assets':
    command => 'php app/console assets:install --symlink'
  } ->

  exec { 'assetic':
    command => 'php app/console assetic:dump',
    onlyif => 'php bin/console | grep assetic'
  } ->

  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploysf2'
  }

}

# == Class: pm::deploy::symfony3
#
# Deploy the symfony3 framework from the documentroot of the project
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::symfony3 {
  $docroot = hiera('docrootgit', '/var/www/html')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.deploysf3',
    cwd => "${docroot}/server",
    environment => ["HOME=/home/modem"],
    timeout => 1800,
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  }

  # Ensure the logs/cache directory exists with the right permissions
  file { "${docroot}/server/app/logs":
    ensure            =>  directory,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0770'
  } ->

  # Ensure the logs/cache directory exists with the right permissions
  file { "${docroot}/server/app/cache":
    ensure            =>  directory,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0770'
  } ->

  exec { 'npmsh':
    command => "npm.sh ${docroot} >/home/modem/lognpm 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800
  } ->

  exec { 'composersh':
    command => "composer.sh ${docroot} >/home/modem/logcomposer 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800
  } ->

  exec { 'parameters_dbname':
    command => 'sed -i "s,database_name:.*$,database_name: s_bdd," app/config/parameters.yml'
  } ->

  exec { 'parameters_dbuser':
    command => 'sed -i "s,database_user:.*$,database_user: s_bdd," app/config/parameters.yml'
  } ->

  exec { 'parameters_dbpasswd':
    command => 'sed -i "s,database_password:.*$,database_password: s_bdd," app/config/parameters.yml'
  } ->

  exec { 'parameters_mongoserver':
    command => 'sed -i "s,mongodb_server:.*$,mongodb_server: mongodb://localhost:27017," app/config/parameters.yml'
  } ->

  exec { 'parameters_mongoname':
    command => 'sed -i "s,mongodb_default_name:.*$,mongodb_default_name: mongodb," app/config/parameters.yml'
  } ->

  exec { 'rmcachedev':
    command => 'rm -rf app/cache/dev',
    onlyif => 'test -d app/cache/dev'
  } ->

  exec { 'rmcacheprod':
    command => 'rm -rf app/cache/prod',
    onlyif => 'test -d app/cache/prod'
  } ->

  exec { 'schema':
    command => 'php bin/console doctrine:schema:create',
    onlyif => 'ps aux | grep mysqld | grep -v grep'
  } ->

  exec { 'assets':
    command => 'php bin/console assets:install --symlink'
  } ->

  exec { 'assetic':
    command => 'php bin/console assetic:dump',
    onlyif => 'php bin/console | grep assetic'
  } ->

  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploysf3'
  }

}


# == Class: pm::deploy::static
#
# Deploy a simple php project (neither framework, neither cms) from the documentroot of the project
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::static {
  $docroot = hiera('docrootgit', '/var/www/html')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.deploystatic',
    environment => ["HOME=/home/modem"],
    timeout => 1800,
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  }

  exec { 'npmsh':
    command => "npm.sh ${docroot} >/home/modem/lognpm 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800
  } ->

  exec { 'composersh':
    command => "composer.sh ${docroot} >/home/modem/logcomposer 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800,
    onlyif => 'test -f /usr/bin/php'
  } ->

  exec { 'mvnsh':
    command => "mvn.sh ${docroot} >/home/modem/logmvn 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 7200,
    onlyif => 'test -f /usr/bin/mvn'
  } ->

  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploystatic'
  }
}

# == Class: pm::deploy::noweb
#
# Deploy a noweb project, for batch or cli purposes
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::noweb {
  $docroot = hiera('docrootgit', '/var/www/html')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.deploynoweb',
    environment => ["HOME=/home/modem"],
    timeout => 1800,
    require => [ Exec['touchdeploygit'] ]
  }

  exec { 'npmsh':
    command => "npm.sh ${docroot} >/home/modem/lognpm 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800
  } ->

  exec { 'composersh':
    command => "composer.sh ${docroot} >/home/modem/logcomposer 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800,
    onlyif => 'test -f /usr/bin/php'
  } ->

  exec { 'mvnsh':
    command => "mvn.sh ${docroot} >/home/modem/logmvn 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 7200,
    onlyif => 'test -f /usr/bin/mvn'
  } ->

  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploynoweb'
  }
}

# == Class: pm::deploy::nodejs
#
# Launch nodejs app if exists on the project repo
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::nodejs {
  $docroot = hiera('docrootgit', '/var/www/html')
  $weburi = hiera('weburi', '')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.deploynodejs',
    environment => ["HOME=/home/modem", "PORT=3100"],
    cwd => "${docroot}/nodejs",
    timeout => 1800,
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  }

  exec { 'pm2start':
    command => 'pm2 start -f app.js',
    onlyif => 'test -f app.js',
    require => Exec['npmsh']
  } ->

  exec { 'pm2start_server':
    command => 'pm2 start -f server.js',
    onlyif => 'test -f server.js',
    require => Exec['npmsh']
  } ->

  # reactjs start
  exec { 'pm2start_server_bin':
    command => 'pm2 start -f bin/server.js',
    environment => ["HOME=/home/modem", "PORT=3100", "NODE_PATH=./src", "APIPORT=3200", "HOST=nodejs.${weburi}", "APIHOST=127.0.0.1"],
    onlyif => 'test -f bin/server.js',
    require => Exec['npmsh']
  } ->

  # reactjs start
  exec { 'pm2start_api_bin':
    command => 'pm2 start -f bin/api.js',
    environment => ["HOME=/home/modem", "PORT=3100", "NODE_PATH=./src", "APIPORT=3200", "HOST=nodejs.${weburi}", "APIHOST=127.0.0.1"],
    onlyif => 'test -f bin/api.js',
    require => Exec['npmsh']
  } ->

  exec { 'touchdeploynodejs':
    command => 'touch /home/modem/.deploynodejs'
  }
}


# == Class: pm::deploy::drupal
#
# Deploy a drupal cms from the documentroot of the project
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::drupal {
  $docroot = hiera('docrootgit', '/var/www/html')
  $email = hiera('email', 'test@yopmail.com')
  $projectname = hiera('project', 'currentproject')
  $framework = hiera('framework', 'Drupal8')
  $username = hiera('httpuser', 'admin')
  $adminpass = hiera('httppasswd', 'nextdeploy')
  $iscache = hiera('iscache', '0')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  }

  exec {'resetopcache':
    command => "php -r 'opcache_reset();'",
    creates => '/home/modem/.deploydrupal'
  } ->

  exec {'sleepopcache':
    command => "sleep 10",
    creates => '/home/modem/.deploydrupal'
  } ->

  exec { 'npmsh':
    command => "npm.sh ${docroot} >/home/modem/lognpm 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    creates => '/home/modem/.deploydrupal',
    timeout => 1800
  } ->

  exec { 'composersh':
    command => "composer.sh ${docroot} >/home/modem/logcomposer 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    creates => '/home/modem/.deploydrupal',
    timeout => 1800
  } ->

  exec { 'getdrush':
    command => 'wget http://files.drush.org/drush.phar',
    creates => '/usr/local/bin/drush',
    user => 'modem',
    group => 'www-data',
    cwd => '/tmp'
  } ->

  exec { 'chmodrush':
    command => 'chmod +x drush.phar',
    creates => '/usr/local/bin/drush',
    cwd => '/tmp'
  } ->

  exec { 'mvdrush':
    command => 'mv drush.phar /usr/local/bin/drush',
    creates => '/usr/local/bin/drush',
    user => 'root',
    cwd => '/tmp'
  } ->

  exec {'site-install':
    command => "/usr/local/bin/drush -y site-install --db-url=mysql://s_bdd:s_bdd@localhost:3306/s_bdd --locale=en --account-name=${username} --account-pass=${adminpass} --site-name=${projectname} --account-mail=${email} --site-mail=${email} standard >/dev/null 2>&1",
    cwd => "${docroot}/server",
    user => 'modem',
    group => 'www-data',
    environment => ["HOME=/home/modem", "USER=modem", "LC_ALL=en_US.UTF-8", "LANG=en_US.UTF-8", "LANGUAGE=en_US.UTF-8", "SHELL=/bin/bash", "TERM=xterm"],
    timeout => 3600,
    creates => '/home/modem/.deploydrupal'
  } ->

  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploydrupal',
    user => 'modem',
    group => 'www-data',
    creates => '/home/modem/.deploydrupal'
  }

  if $iscache == "yes" {
    case $framework {
      'Drupal6': {
        exec { 'memcachesettingsd6':
          command => 'echo  "\$conf[\'cache_inc\'] = \'./sites/all/modules/memcache/memcache.inc\';\$conf[\'memcache_bins\'] = array(\'cache\' => \'default\', \'cache_form\' => \'database\');" >> sites/default/settings.php',
          cwd => "${docroot}/server",
          user => 'root',
          creates => '/home/modem/.deploydrupal',
          require => Exec['site-install'],
          before => Exec['touchdeploy']
        }
      }
      'Drupal7': {
        exec { 'memcachesettingsd7':
          command => 'echo  "\$conf[\'cache_backends\'][] = \'./sites/all/modules/memcache/memcache.inc\';\$conf[\'cache_default_class\'] = \'MemCacheDrupal\';\$conf[\'cache_class_cache_form\'] = \'DrupalDatabaseCache\';" >> sites/default/settings.php',
          cwd => "${docroot}/server",
          user => 'root',
          creates => '/home/modem/.deploydrupal',
          require => Exec['site-install'],
          before => Exec['touchdeploy']
        }
      }
      'Drupal8': {
        exec { 'memcachesettingsd8':
          command => 'drush -y pm-enable memcache >/dev/null 2>&1',
          cwd => "${docroot}/server",
          user => 'modem',
          group => 'www-data',
          creates => '/home/modem/.deploydrupal',
          environment => ["HOME=/home/modem", "USER=modem", "LC_ALL=en_US.UTF-8", "LANG=en_US.UTF-8", "LANGUAGE=en_US.UTF-8", "SHELL=/bin/bash", "TERM=xterm"],
          require => Exec['site-install']
        } ->

        exec {'drush-cr':
          command => "/usr/local/bin/drush cr >/dev/null 2>&1",
          cwd => "${docroot}/server",
          user => 'modem',
          group => 'www-data',
          environment => ["HOME=/home/modem", "USER=modem", "LC_ALL=en_US.UTF-8", "LANG=en_US.UTF-8", "LANGUAGE=en_US.UTF-8", "SHELL=/bin/bash", "TERM=xterm"],
          timeout => 100,
          creates => '/home/modem/.deploydrupal',
          before => Exec['touchdeploy']
        }
      }
    }
  }
}


# == Class: pm::deploy::wordpress
#
# Deploy a wordpress cms from the documentroot of the project
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::deploy::wordpress {
  $docroot = hiera('docrootgit', '/var/www/html')
  $email = hiera('email', 'test@yopmail.com')
  $weburi = hiera('weburi', '')
  $commit = hiera('commit', 'HEAD')
  $username = hiera('httpuser', 'admin')
  $adminpass = hiera('httppasswd', 'nextdeploy')
  $projectname = hiera('project', 'currentproject')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.deploywp',
    cwd => "${docroot}/server",
    environment => ["HOME=/home/modem"],
    timeout => 1800,
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  }

  exec { 'npmsh':
    command => "npm.sh ${docroot} >/home/modem/lognpm 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 1800
  } ->

  exec { 'wp-cli1':
    command => 'curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar',
    cwd => '/tmp'
  } ->

  exec { 'wp-cli2':
    command => 'chmod +x /tmp/wp-cli.phar'
  } ->

  exec { 'wp-cli3':
    command => 'mv /tmp/wp-cli.phar /usr/local/bin/wp',
    user => 'root'
  } ->

  exec { 'dlwp':
    command => 'wp core download', # --locale=fr_FR',
    unless => 'test -d wp-admin'
  } ->

  exec { 'configwp':
    command => 'wp core config --dbname=s_bdd --dbuser=s_bdd --dbpass=s_bdd',
    unless => 'test -f wp-config.php'
  } ->

  exec { 'gitresetwp':
    command => "git reset --hard ${commit}",
    user => 'modem',
    cwd => "${docroot}",
    group => 'www-data'
  } ->

  exec { 'installbdd':
    command => "wp core install --url=${weburi} --title=${projectname} --admin_user=${username} --admin_password=${adminpass} --admin_email=${email}"
  } ->

  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploywp'
  }
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
  $weburi = hiera('weburi', '')
  $email = hiera('email')
  $nextdeployuri = hiera('nextdeployuri', 'nextdeploy.local')
  $project = hiera('project', '')
  $framework = hiera('framework', 'static')
  $ftpuser = hiera('ftpuser', 'nextdeploy')
  $ftppasswd = hiera('ftppasswd', 'nextdeploy')
  $ismysql = hiera('ismysql', 0)
  $ismongo = hiera('ismongo', 0)
  $vm_name = hiera('name', 'undefined')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    cwd => "${docroot}",
    environment => ["HOME=/home/modem"],
    unless => 'test -f /home/modem/.postinstall',
    user => 'modem',
    group => 'www-data',
    require => Exec['touchdeploy'],
    timeout => 1800
  }

  exec { 'hosts_writable':
    command => 'chmod 777 /etc/hosts',
    user => 'root'
  } ->

  exec { 'touch_importsh':
    command => 'touch scripts/import.sh',
  } ->

  exec { 'chmod_importsh':
    command => 'chmod +x scripts/import.sh',
  } ->

  exec { 'touch_postinstallsh':
    command => 'touch scripts/postinstall.sh',
  } ->

  exec { 'chmod_postinstallsh':
    command => 'chmod +x scripts/postinstall.sh',
  } ->

  exec { 'importsh':
    command => "import.sh --uri ${weburi} --framework ${framework} --ftpuser ${ftpuser} --ftppasswd ${ftppasswd} --ismysql ${ismysql} --ismongo ${ismongo} >/home/modem/import.log 2>&1",
    timeout => 14400,
    require => File['/usr/local/bin/import.sh']
  } ->

  exec { 'postinstall':
    command => "/bin/bash scripts/postinstall.sh ${weburi} >/home/modem/postinstall.log 2>&1",
    timeout => 7200
  } ->

  exec { 'touch_cron':
    command => 'touch scripts/crontab',
  } ->

  exec { 'copy_cron':
    command => 'cp scripts/crontab /var/spool/cron/crontabs/modem',
    user => 'root'
  } ->

  exec { 'chown_cron':
    command => 'chown modem: /var/spool/cron/crontabs/modem',
    user => 'root'
  } ->

  exec { 'chmod_cron':
    command => 'chmod 600 /var/spool/cron/crontabs/modem',
    user => 'root'
  } ->

  exec { 'restart_cron':
    command => 'service cron restart',
    user => 'root'
  } ->

  exec { 'restartvarnish_postinstall':
    command => 'service varnish restart',
    onlyif => 'test -d /etc/varnish',
    user => 'root'
  } ->

  exec { 'touchstatusok':
    command => 'touch /var/www/status_ok',
    user => 'root'
  } ->

  exec { 'chownstatusok':
    command => 'chown modem: /var/www/status_ok',
    user => 'root'
  } ->

  exec { 'mail_endinstall':
    command => "echo 'Your vm for the project ${project} is installed and ready to work. Connect to your NextDeploy account (https://ui.${nextdeployuri}/) for getting urls and others access.' | mail -s '[NextDeploy] Vm installed' ${email}"
  } ->

  exec { 'curl_setupcomplete':
    command => "curl -X PUT -k -s https://api.${nextdeployuri}/api/v1/vms/${vm_name}/setupcomplete >/dev/null 2>&1"
  } ->

  exec { 'touchpostinstall':
    command => 'touch /home/modem/.postinstall'
  } ->

  exec { 'refreshcommit':
    command => "refreshcommit.sh ${nextdeployuri} ${vm_name}",
    unless => 'test "ok" = "nok"',
    require => File['/usr/local/bin/refreshcommit.sh']
  }
}
