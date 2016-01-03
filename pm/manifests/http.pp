# == Class: pm::http
#
# Install apache / php with help of official modules
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::http {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  # apache setting
  class { '::apache':
    default_mods        => false,
    default_vhost => false,
    mpm_module => 'prefork',
    service_ensure => true,
    user => 'modem',
    manage_user => false,
    logroot_mode => '0775'
  }

  file { '/etc/apache2/mime.types':
   ensure => 'link',
   target => '/etc/mime.types',
  }

  # enable apache modules
  apache::mod { 'rewrite': }
  apache::mod { 'actions': }
  apache::mod { 'auth_basic': }
  apache::mod { 'autoindex': }
  apache::mod { 'deflate': }
  apache::mod { 'env': }
  apache::mod { 'expires': }
  apache::mod { 'headers': }
  apache::mod { 'setenvif': }
  apache::mod { 'status': }
  apache::mod { 'mpm_prefork': }
  apache::mod { 'access_compat': }
  apache::mod { 'authn_core': }
  #apache::mod { 'authz_core': }

  # avoid issue when restart apache2.4
  file { '/etc/apache2/conf.d/tt.conf':
    content => ''
  }
  ->
  # add status setting
  file { '/etc/apache2/mods-enabled/status.conf':
    ensure => 'link',
    target => '/etc/apache2/mods-available/status.conf'
  }
  ->
  # alias for a disallow-all robots.txt
  file { '/var/www/robots.txt':
    owner => 'www-data',
    group => 'www-data',
    content => 'User-agent: *
Disallow: /'
  }
  ->
  # force home for apache into modem folder
  exec { 'apacheHOME':
    command => 'echo "export HOME=/home/modem" >> /etc/apache2/envvars',
    unless => 'grep "/home/modem" /etc/apache2/envvars >/dev/null 2>&1'
  }

  $vhost_params = hiera("apache_vhost", [])
  create_resources("apache::vhost", $vhost_params, { require => [ File['/etc/apache2/conf.d/tt.conf'], Exec['touchdeploygit'] ], before => Service['varnish'] })

  $kvhost = keys($vhost_params)
  class {'::apache::mod::php':}

  php::ini { '/etc/php5/apache2/php.ini':
    display_errors => 'Off',
    memory_limit   => '1024M',
    max_execution_time => '0',
    date_timezone => 'Europe/Paris',
    session_cookie_httponly => '1',
    session_save_path => '/tmp',
    post_max_size => '150M',
    upload_max_filesize => '150M',
    error_reporting => "E_ALL & ~E_DEPRECATED & ~E_NOTICE",
    default_socket_timeout => '600'
  }

  class { 'php::cli':}
  ->
  package { [ 'php-pear', 'php5-dev']:
    ensure => installed,
  }

  php::ini { '/etc/php5/cli/php.ini':
    memory_limit   => '-1',
    date_timezone => 'Europe/Paris',
    max_execution_time => '0',
    display_errors => 'On'
  }

  #install mongo extension only if mongo is part of the project
  $ismongo = hiera("ismongo", 0)
  if $ismongo == 1 {
    exec { "pecl-mongo":
      command => "/usr/bin/yes '' | /usr/bin/pecl install --force mongo-1.5.8",
      user => "root",
      environment => ["HOME=/root"],
      unless => '/usr/bin/test -f /etc/php5/apache2/conf.d/20-mongo.ini',
      require => [ Package['php-pear'], Package['php5-dev'] ]
    }
    ->

    file { "/etc/php5/apache2/conf.d/20-mongo.ini":
      content => "extension=mongo.so",
      owner => "root"
    }
    ->

    file { "/etc/php5/cli/conf.d/20-mongo.ini":
      content => "extension=mongo.so",
      owner => "root"
    }
  }

  php::module { [ 'mysql', 'redis', 'memcached', 'gd', 'curl', 'intl', 'mcrypt' ]: }

  # install pm_tools only if auth is enabled
  $isauth = hiera("isauth", 0)
  if $isauth == 1 {
    file { '/var/www/pm_tools':
      ensure => directory,
      recurse => remote,
      source => 'puppet:///modules/pm/pm_tools'
    }
  }

  class { 'pm::monitor::collect::apache': }
}