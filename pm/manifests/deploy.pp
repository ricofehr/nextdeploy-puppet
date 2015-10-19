# == Class: pm::deploy::vhost
#
# Create the documentroot and clone the git repository
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::deploy::vhost {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    unless => 'test -f /home/modem/.deploygit'
  }

  $docroot = hiera('docrootgit', '/var/www/html')
  $gitpath = hiera('gitpath', '')
  $branch = hiera('branch', 'master')
  $commit = hiera('commit', 'HEAD')

  exec { 'nohostvalidation':
    command => 'echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config',
    user => 'root'
  }
  ->
  exec { 'mkdir_docroot':
    command => "mkdir -p ${docroot}",
    user => 'root'
  }
  ->
  exec { 'chown_varwww':
    command => "chown -R modem:www-data ${docroot}",
    user => 'root'
  }
  ->
  exec { 'gitclone':
    command => "git clone -b ${branch} ${gitpath} ${docroot}",
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    unless => "test -d ${docroot}/.git",
    require => [ Package['git-core'], File['/home/modem/.ssh/id_rsa'] ]
  }
  ->
  exec { 'gitreset':
    command => "git reset --hard ${commit}",
    user => 'modem',
    cwd => "${docroot}",
    group => 'www-data'
  }
  ->
  exec { 'touchdeploygit':
    command => 'touch /home/modem/.deploygit',
    user => 'modem'
  }

}


# == Class: pm::deploy::symfony2
#
# Deploy the symfony2 framework from the documentroot of the project
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
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
  }
  ->
  # Ensure the logs/cache directory exists with the right permissions
  file { "${docroot}/server/app/cache":
    ensure            =>  directory,
    owner             =>  modem,
    group             =>  www-data,
    mode              =>  '0770'
  }
  ->
  exec { 'composerdl':
    command => 'curl -sS https://getcomposer.org/installer | php',
    unless => 'test -f composer.phar'
  }
  ->
  exec { 'composer':
    command => 'php composer.phar install -n --prefer-source'
  }
  ->
  exec { 'parameters_dbname':
    command => 'sed -i "s,database_name:.*$,database_name: s_bdd," app/config/parameters.yml'
  }
  ->
  exec { 'parameters_dbuser':
    command => 'sed -i "s,database_user:.*$,database_user: s_bdd," app/config/parameters.yml'
  }
  ->
  exec { 'parameters_dbpasswd':
    command => 'sed -i "s,database_password:.*$,database_password: s_bdd," app/config/parameters.yml'
  }
  ->
  exec { 'parameters_mongoserver':
    command => 'sed -i "s,mongodb_server:.*$,mongodb_server: mongodb://localhost:27017," app/config/parameters.yml'
  }
  ->
  exec { 'parameters_mongoname':
    command => 'sed -i "s,mongodb_default_name:.*$,mongodb_default_name: mongodb," app/config/parameters.yml'
  }
  ->
  exec { 'schema':
    command => 'php app/console doctrine:schema:create',
    onlyif => 'ps aux | grep mysqld | grep -v grep'
  }
  ->
  exec { 'assets':
    command => 'php app/console assets:install --symlink'
  }
  ->
  exec { 'assetic':
    command => 'php app/console assetic:dump'
  }
  ->
  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploysf2'
  }

}


# == Class: pm::deploy::static
#
# Deploy a simple php project (neither framework, neither cms) from the documentroot of the project
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::deploy::static {
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.deploystatic',
    environment => ["HOME=/home/modem"],
    timeout => 1800,
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  }

  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploystatic'
  }
}

# == Class: pm::deploy::nodejs
#
# Launch nodejs app if exists on the project repo
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::deploy::nodejs {
  $docroot = hiera('docrootgit', '/var/www/html')

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

  exec { 'npminstall':
    command => 'npm install',
    onlyif => 'test -f package.json'
  } ->
  exec { 'bowerinstall':
    command => 'bower install',
    onlyif => 'test -f bower.json'
  } ->
  exec { 'gruntbuild':
    command => 'grunt build',
    onlyif => 'test -f Gruntfile.js'
  } ->
  exec { 'gulpbuild':
    command => 'gulp build',
    onlyif => 'test -f gulpfile.js'
  } ->
  exec { 'pm2start':
    command => 'pm2 start -f app.js',
    onlyif => 'test -f app.js'
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
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::deploy::drupal {
  $docroot = hiera('docrootgit', '/var/www/html')
  $email = hiera('email', 'test@yopmail.com')

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'test -f /home/modem/.deploydrupal',
    cwd => "${docroot}/server",
    environment => ["HOME=/home/modem"],
    timeout => 1800,
    require => [ Service['varnish'], Exec['touchdeploygit'] ]
  }

  exec {'pear-consoletable':
    command => 'pear install -f Console_Table',
    user => 'root',
    require => Package['php-pear']
  }
  ->
  exec {'pear-drushchannel':
    command => 'pear channel-discover pear.drush.org',
    user => 'root',
    unless => 'pear list-channels | grep pear.drush.org'
  }
  ->
  exec {'drush-install':
    command => 'pear install -f drush/drush',
    user => 'root',
    onlyif => 'test ! -f /usr/bin/drush',
  }
  ->
  exec {'site-install':
    command => "drush -y site-install --locale=en --db-url=mysql://s_bdd:s_bdd@localhost:3306/s_bdd --account-pass=modem --site-name=vm --account-mail=${email} --site-mail=${email} standard"
  }
  ->
  exec { 'touchdeploy':
    command => 'touch /home/modem/.deploydrupal'
  }
}


# == Class: pm::deploy::wordpress
#
# Deploy a wordpress cms from the documentroot of the project
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::deploy::wordpress {
  $docroot = hiera('docrootgit', '/var/www/html')
  $email = hiera('email', 'test@yopmail.com')
  $weburi = hiera('weburi', '')
  $commit = hiera('commit', 'HEAD')

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

  exec { 'wp-cli1':
    command => 'curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar',
    cwd => '/tmp'
  }
  ->
  exec { 'wp-cli2':
    command => 'chmod +x /tmp/wp-cli.phar'
  }
  ->
  exec { 'wp-cli3':
    command => 'mv /tmp/wp-cli.phar /usr/local/bin/wp',
    user => 'root'
  }
  ->
  exec { 'dlwp':
    command => 'wp core download', # --locale=fr_FR',
    unless => 'test -d wp-admin'
  }
  ->
  exec { 'configwp':
    command => 'wp core config --dbname=s_bdd --dbuser=s_bdd --dbpass=s_bdd',
    unless => 'test -f wp-config.php'
  }
  ->
  exec { 'gitresetwp':
    command => "git reset --hard ${commit}",
    user => 'modem',
    cwd => "${docroot}",
    group => 'www-data'
  }
  ->
  exec { 'installbdd':
    command => "wp core install --url=${weburi} --title=vm --admin_user=modem --admin_password=modem --admin_email=${email}"
  }
  ->
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
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::deploy::postinstall {
  $docroot = hiera('docrootgit', '/var/www/html')
  $weburi = hiera('weburi', '')
  $email = hiera('email')
  $mvmcuri = hiera('mvmcuri', 'mvmc.local')
  $project = hiera('project', '')
  $framework = hiera('framework', 'static')
  $ftpuser = hiera('ftpuser', 'mvmc')
  $ftppasswd = hiera('ftppasswd', 'mvmc')
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

  exec { 'touch_postinstallsh':
    command => 'touch scripts/postinstall.sh',
  }
  ->
  exec { 'chmod_postinstallsh':
    command => 'chmod +x scripts/postinstall.sh',
  }
  ->
  exec { 'postinstall':
    command => "/bin/bash scripts/postinstall.sh --uri ${weburi} --uri-admin admin.${weburi} --uri-mobile m.${weburi} --framework ${framework} --ftpuser ${ftpuser} --ftppasswd ${ftppasswd} --ismysql ${ismysql} --ismongo ${ismongo} > /home/modem/postinstall.log",
  }
  ->
  exec { 'touch_cron':
    command => 'touch scripts/crontab',
  }
  ->
  exec { 'copy_cron':
    command => 'cp scripts/crontab /var/spool/cron/crontabs/modem',
    user => 'root'
  }
  ->
  exec { 'chown_cron':
    command => 'chown modem: /var/spool/cron/crontabs/modem',
    user => 'root'
  }
  ->
  exec { 'chmod_cron':
    command => 'chmod 600 /var/spool/cron/crontabs/modem',
    user => 'root'
  }
  ->
  exec { 'restart_cron':
    command => 'service cron restart',
    user => 'root'
  }
  ->
  exec { 'restartvarnish_postinstall':
    command => 'service varnish restart',
    user => 'root'
  }
  ->
  exec { 'touchstatusok':
    command => 'touch /var/www/status_ok',
    user => 'root'
  }
  ->
  exec { 'chownstatusok':
    command => 'chown modem: /var/www/status_ok',
    user => 'root'
  }  
  ->
  exec { 'mail_endinstall':
    command => "echo 'Your vm for the project ${project} is installed and ready to work. Connect to your mvmc account (http://${mvmcuri}/) for getting urls and others access.' | mail -s '[MVMC] Vm installed' ${email}"
  }
  ->
  exec { 'curl_setupcomplete':
    command => "curl -X PUT -s http://${mvmcuri}/api/v1/vms/${vm_name}/setupcomplete >/dev/null 2>&1"
  }
  ->
  exec { 'touchpostinstall':
    command => 'touch /home/modem/.postinstall'
  }
}