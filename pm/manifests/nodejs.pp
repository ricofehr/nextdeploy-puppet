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

# nodejs and ember_build prerequisites
  class { '::nodejs':
    repo_url_suffix => 'node_4.x',
    # nodejs_dev_package_ensure => 'present',
    # npm_package_ensure        => 'present',
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
}