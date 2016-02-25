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
  file { '/usr/bin/node':
    ensure   => 'link',
    target => '/usr/bin/nodejs',
  }
  ->
  package { ['pm2', 'grunt-cli', 'grunt', 'bower', 'gulp']:
    ensure   => present,
    provider => 'npm',
  }

  # ensure that apt-update is running before install nodejs package
  Apt::Source <| |> ~> Class['apt::update'] -> Package['nodejs']
}