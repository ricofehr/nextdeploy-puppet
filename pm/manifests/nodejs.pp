# == Class: pm::nodejs
#
# Install nodejs / npm
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::nodejs {
  $node_version = hiera('node_version', '4.x')

  # nodejs and ember_build prerequisites
  class { '::nodejs':
    repo_url_suffix => "${node_version}"
  }
  ->
  # ensure node binary exists
  exec { 'node-symlink':
    command => '/bin/ln -sf /usr/bin/nodejs /usr/bin/node',
    user => 'root',
    creates => '/usr/bin/node'
  }
  ->
  package { ['pm2', 'grunt-cli', 'bower', 'gulp']:
    ensure   => present,
    provider => 'npm',
    before => File['/usr/local/bin/npm.sh']
  }

  exec { 'nodejs-aptupdate':
    command => "/usr/bin/apt-get update",
    timeout => 1800,
    user => 'root',
    creates => '/usr/bin/node'
  }

  # ensure that apt-update is running before install nodejs package
  Apt::Source <| |> ~> Exec['nodejs-aptupdate'] -> Package['nodejs']
}
