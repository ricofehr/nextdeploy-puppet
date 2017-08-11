# == Class: pm::tool::wkhtmltopdf
#
# Install wkhtmltopdf with qt patched
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::tool::wkhtmltopdf ($major = '0.12', $minor = '4') {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  exec { 'tmpwkhtml':
    command => 'mkdir /tmp/wkhtml',
    user => 'root',
    creates => '/usr/bin/wkhtmltopdf'
  } ->

  exec { 'getwkhtml':
    command => "wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${major}.${minor}/wkhtmltox-${major}.${minor}_linux-generic-amd64.tar.xz",
    cwd => '/tmp/wkhtml',
    user => 'root',
    creates => '/usr/bin/wkhtmltopdf',
    require => Package['wget']
  } ->

  exec { 'installwkhtml-step1':
    command => "tar xvf wkhtmltox-${major}.${minor}_linux-generic-amd64.tar.xz",
    cwd => '/tmp/wkhtml',
    user => 'root',
    creates => '/usr/bin/wkhtmltopdf'
  } ->

  exec { 'installwkhtml-step2':
    command => 'mv wkhtmltox/bin/wkhtmltopdf /usr/bin/',
    cwd => '/tmp/wkhtml',
    user => 'root',
    creates => '/usr/bin/wkhtmltopdf'
  } ->

  exec { 'cleanwkhtmlinstall':
    command => 'rm -rf /tmp/wkhtml',
    user => 'root',
    onlyif => 'test -d /tmp/wkhtml'
  }
}

# == Class: pm::tool::phpapc
#
# Install apc
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::tool::phpapc {
  ensure_packages(['php-apc'])
}

# == Class: pm::tool::imagemagick
#
# Install imagemagick
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::tool::imagemagick {
  $isweb = hiera('iswebserver', 0)

  ensure_packages(['imagemagick'])
  if $isweb == 1 {
    #php7 for xenial
    if ($::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '16.04') < 0) or ($::operatingsystem == 'Debian' and versioncmp($::operatingsystemrelease, '9') < 0) {
        ensure_packages(['php5-imagick'])
    }
    else {
        ensure_packages(['php7.0-imagick'])
    }
  }
}
