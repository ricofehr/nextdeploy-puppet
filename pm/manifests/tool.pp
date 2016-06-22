# == Class: pm::tool::wkhtmltopdf
#
# Install wkhtmltopdf with qt patched
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::tool::wkhtmltopdf ($major = '0.12', $minor = '3') {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  exec { 'tmpwkhtml':
    command => 'mkdir /tmp/wkhtml',
    user => 'root',
    creates => '/usr/bin/wkhtmltopdf'
  } ->

  exec { 'getwkhtml':
    command => "wget http://download.gna.org/wkhtmltopdf/${major}/${major}.${minor}/wkhtmltox-${major}.${minor}_linux-generic-amd64.tar.xz",
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