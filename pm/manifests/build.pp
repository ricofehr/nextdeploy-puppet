define pm::build(
  $absolute = $name,
  $path,
  $envvars = [],
  $aliases = [],
  $framework,
  $rewrites = '',
  $publicfolder = '',
) {

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  exec { "ci-npmsh-${path}":
    command => "npm.sh ${docroot} >/home/modem/lognpm 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    unless => 'diff /tmp/commithash1 /tmp/commithash2',
    timeout => 1800,
    require => Exec['recordcommit2']
  } ->

  exec { "ci-composersh-${path}":
    command => "composer.sh ${docroot} >/home/modem/logcomposer 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    unless => 'diff /tmp/commithash1 /tmp/commithash2',
    timeout => 1800
  } ->

  exec { "ci-mvnsh-${path}":
    command => "mvn.sh ${docroot} >/home/modem/logmvn 2>&1",
    environment => ["HOME=/home/modem"],
    user => 'modem',
    group => 'www-data',
    cwd => '/home/modem',
    timeout => 7200,
    unless => 'diff /tmp/commithash1 /tmp/commithash2',
    onlyif => 'test -f /usr/bin/mvn'
  }

  case $framework {
      'symfony2': {
        pm::build::symfony { "${project}${path}":
          version => 2,
          path => "${path}",
          absolute => "${absolute}",
          require => [ Exec["ci-composersh-${path}"], Exec["ci-npmsh-${path}"] ]
        }
      }

      'symfony3': {
        pm::build::symfony { "${project}${path}":
          version => 3,
          path => "${path}",
          require => [ Exec["ci-composersh-${path}"], Exec["ci-npmsh-${path}"] ],
        }
      }

      'drupal6': {
        pm::build::drupal { "${project}${path}":
          version => 6,
          path => "${path}",
          require => [ Exec["ci-composersh-${path}"], Exec["ci-npmsh-${path}"] ]
        }
      }

      'drupal7': {
        pm::build::drupal { "${project}${path}":
          version => 7,
          path => "${path}",
          require => [ Exec["ci-composersh-${path}"], Exec["ci-npmsh-${path}"] ]
        }
      }

      'drupal8': {
        pm::build::drupal { "${project}${path}":
          version => 8,
          path => "${path}",
          require => [ Exec["ci-composersh-${path}"], Exec["ci-npmsh-${path}"] ]
        }
      }

      'nodejs': {
        pm::build::nodejs { "${project}${path}":
          path => "${path}",
          envvars => $envvars,
          require => [ Exec["ci-npmsh-${path}"] ]
        }
      }

      'reactjs': {
        pm::build::reactjs { "${project}${path}":
          path => "${path}",
          envvars => $envvars,
          require => [ Exec["ci-npmsh-${path}"] ]
        }
      }
  }
}


define pm::build::drupal(
  $version = 7,
  $path,
) {

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"
  
  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    unless => 'diff /tmp/commithash1 /tmp/commithash2'
  }

  if $version == 8 {
    exec { "ci-cim-${path}":
      command => 'drush -y cim',
      cwd => "${docroot}",
      require => Exec["ci-composersh-${path}"],
      before => Exec["ci-updb-${path}"]
    }
  }

  exec { "ci-updb-${path}":
    command => 'drush updb -y',
    cwd => "${docroot}",
    require => Exec["ci-composersh-${path}"]
  }

  if $version == 8 {
    exec { "ci-cr-${path}":
      command => 'drush -y cr',
      cwd => "${docroot}",
      require => Exec["ci-updb-${path}"]
    }
  } else {
    exec { "ci-cc-${path}":
      command => 'drush -y cc all',
      cwd => "${docroot}",
      require => Exec["ci-updb-${path}"]
    }
  }
}

define pm::build::symfony(
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
    timeout => 1800,
    unless => 'diff /tmp/commithash1 /tmp/commithash2'
  }

  exec { "ci-schema-${path}":
    command => "php ${consolebin} doctrine:schema:update --force --env=${webenv}",
    onlyif => "ps aux | grep mysqld | grep -v grep",
    cwd => "${docroot}"
  } ->

  exec { "ci-assets-${path}":
    command => "php ${consolebin} assets:install --symlink --env=${webenv}",
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "ci-assetic-${path}":
    command => "php ${consolebin} assetic:dump --env=${webenv}",
    onlyif => "php ${consolebin} | grep assetic",
    creates => "/home/modem/.deploy${path}",
    cwd => "${docroot}"
  } ->

  exec { "ci-rmcachedev-${path}":
    command => 'rm -rf app/cache/dev',
    onlyif => 'test -d app/cache/dev',
    cwd => "${docroot}"
  } ->

  exec { "ci-rmcacheprod-${path}":
    command => 'rm -rf app/cache/prod',
    onlyif => 'test -d app/cache/prod',
    cwd => "${docroot}"
  }
}

define pm::build::nodejs(
  $path = "nodejs",
  $envvars = ["HOME=/home/modem", "PORT=3100"]
) {

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    timeout => 1800,
    unless => 'diff /tmp/commithash1 /tmp/commithash2'
  }

  exec { "ci-pm2stop-${path}":
    command => "pm2 stop -f ${path}-app",
    onlyif => 'test -f app.js',
    cwd => "${docroot}",
    require => [ Exec["ci-npmsh-${path}"] ],
  } ->

  exec { "ci-pm2stop_server-${path}":
    command => "pm2 stop -f ${path}-server",
    onlyif => 'test -f server.js',
    cwd => "${docroot}"
  }

  exec { "ci-pm2start-${path}":
    command => "pm2 start -f app.js --name '${path}-app'",
    onlyif => 'test -f app.js',
    environment => $envvars,
    cwd => "${docroot}"
  } ->

  exec { "ci-pm2start_server-${path}":
    command => "pm2 start -f server.js --name '${path}-server'",
    onlyif => 'test -f server.js',
    environment => $envvars,
    cwd => "${docroot}"
  }
}

define pm::build::reactjs(
  $path = "nodejs",
  $envvars = ["HOME=/home/modem", "PORT=3100"]
) {

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ],
    user => 'modem',
    group => 'www-data',
    timeout => 1800,
    unless => 'diff /tmp/commithash1 /tmp/commithash2'
  }

  exec { "ci-pm2stop_server_bin-${path}":
    command => "pm2 stop -f ${path}-server",
    onlyif => 'test -f bin/server.js',
    cwd => "${docroot}",
    require => [ Exec["ci-npmsh-${path}"] ]
  } ->

  # reactjs start
  exec { "ci-pm2stop_api_bin-${path}":
    command => "pm2 stop ${path}-api",
    cwd => "${docroot}",
    onlyif => 'test -f bin/api.js'
  } ->

  exec { "ci-pm2start_server_bin-${path}":
    command => "pm2 start -f bin/server.js --name '${path}-server'",
    onlyif => 'test -f bin/server.js',
    environment => $envvars,
    cwd => "${docroot}"
  } ->

  # reactjs start
  exec { "ci-pm2start_api_bin-${path}":
    command => "pm2 start -f bin/api.js --name '${path}-api'",
    environment => $envvars,
    cwd => "${docroot}",
    onlyif => 'test -f bin/api.js'
  }
}



