# == Class: pm::ci::jenkins
#
# Install jenkins for prepare continuous integration jobs
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::ci::cijenkins {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  $email = hiera('email', 'user@example.com')
  $docrootgit = hiera('docrootgit', '/var/www/html')

  user { 'jenkins':
    name => 'jenkins',
    ensure => 'present',
    allowdupe => true,
    uid => 1000,
    gid => 'www-data',
    home => '/var/lib/jenkins',
    shell => '/bin/bash',
    managehome => false
  }

  class { 'pm::java':
    version => '8'
  } ->

  class {'jenkins':
    port => "9294",
    lts => true,
    install_java => false,
    config_hash => {
       'HTTP_PORT' => { 'value' => '9294' },
    },
    # cli_ssh_keyfile => '/home/modem/.ssh/id_rsa',
    cli => true,
    manage_user => false,
    require => User['jenkins']
  }

  include ::jenkins::cli_helper

  class { '::jenkins::cli::config':
    cli_jar => '/usr/share/jenkins/jenkins-cli.jar',
    url => 'http://localhost:9294',
    puppet_helper => '/usr/share/jenkins/puppet_helper.groovy'
  }

  # jenkins::user { 'modem':
  #    email    => $email,
  #    password => 'modem',
  #    public_key => '/home/modem/.ssh/id_rsa.pub'
  # }

  # class {'jenkins::security':
  #   security_model => 'unsecured'
  # }

  jenkins::plugin { 'ruby-runtime': }
  jenkins::plugin { 'git-client': }
  jenkins::plugin { 'workflow-scm-step': }
  jenkins::plugin { 'structs': }
  jenkins::plugin { 'script-security': }
  jenkins::plugin { 'mailer': }
  jenkins::plugin { 'matrix-project': }
  jenkins::plugin { 'scm-api': }
  jenkins::plugin { 'ssh-credentials': }
  jenkins::plugin { 'plain-credentials': }
  jenkins::plugin { 'display-url-api': }
  jenkins::plugin { 'workflow-step-api': }
  jenkins::plugin { 'junit': }
  jenkins::plugin { 'xvfb': }
  jenkins::plugin { 'git': }
  jenkins::plugin { 'slack': }
  jenkins::plugin { 'gitlab-hook': }
  jenkins::plugin { 'bouncycastle-api': }
  jenkins::plugin { 'ansicolor': }

  ensure_packages(['chromium-browser', 'xvfb'])

  file { '/usr/bin/chrome':
     ensure => 'link',
     target => '/usr/bin/chromium-browser',
     require => Package['chromium-browser']
  }

  file { '/usr/bin/xvfb':
     ensure => 'link',
     target => '/usr/bin/xvfb-run',
     require => Package['xvfb']
  }

  file_line { 'Jenkins disable auth':
     path   => '/var/lib/jenkins/config.xml',
     line   => "  <useSecurity>false</useSecurity>",
     match  => "^  <useSecurity>",
     require => Service['jenkins'],
  } ->

  file { '/var/lib/jenkins/org.jenkinsci.plugins.xvfb.Xvfb.xml':
    content => '<?xml version=\'1.0\' encoding=\'UTF-8\'?>
<org.jenkinsci.plugins.xvfb.Xvfb_-XvfbBuildWrapperDescriptor plugin="xvfb@1.1.3">
  <installations>
    <org.jenkinsci.plugins.xvfb.XvfbInstallation>
      <name>default</name>
      <home></home>
      <properties/>
    </org.jenkinsci.plugins.xvfb.XvfbInstallation>
  </installations>
</org.jenkinsci.plugins.xvfb.Xvfb_-XvfbBuildWrapperDescriptor>'
  } ->

  exec { 'restart-jenkins':
    command => 'service jenkins restart',
    creates => '/home/modem/.jenkinstall'
  } ->

  exec { 'touchjenkinstall':
    command => 'touch /home/modem/.jenkinstall',
    creates => '/home/modem/.jenkinstall'
  }
  #  ->
  #
  # jenkins_authorization_strategy { 'hudson.security.AuthorizationStrategy$Unsecured':
  #   ensure => 'present',
  # }

  file { '/usr/local/bin/resetwebsite.sh':
    source => 'puppet:///modules/pm/tools/resetwebsite.sh',
    owner => 'modem',
    group => 'www-data',
    mode => '0755'
  } ->

  # ensure no-root can cahnge locale
  file_line { 'sudo_rule_resetwebsite':
    path => '/etc/sudoers',
    line => 'jenkins ALL=(ALL) NOPASSWD: /usr/local/bin/resetwebsite.sh',
  } ->

  # ensure no-root can cahnge locale
  file_line { 'sudo_rule_resetwebsite_2':
    path => '/etc/sudoers',
    line => 'modem ALL=(ALL) NOPASSWD: /usr/local/bin/resetwebsite.sh',
  }

  jenkins::job { "build":
    config => multitemplate("pm/jenkins/build.xml.erb"),
    ensure => 'present',
  }

  $uris_params = hiera('uris')
  create_resources("pm::cijob", $uris_params, { require => File_line["Jenkins disable auth"], before => Exec['hosts_writable'] })
}


# == Class: pm::ci::cisonar
#
# Install sonarqube for analyse codebase
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::ci::cisonar {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  class { 'sonarqube':
    version => '5.6',
    require => Class['pm::java']
  }

  sonarqube::plugin { 'sonar-php-plugin':
    groupid    => 'org.sonarsource.php',
    artifactid => 'sonar-php-plugin',
    version => '2.10.0.2087',
    notify => Service['sonar']
  }

  sonarqube::plugin { 'sonar-javascript-plugin':
    groupid    => 'org.sonarsource.javascript',
    artifactid => 'sonar-javascript-plugin',
    version => '3.0.0.4962',
    notify => Service['sonar']
  }

  exec { 'scanner-step1':
    command => 'wget https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip',
    cwd => '/root',
    creates => "/opt/sonar/bin/sonar-scanner",
  } ->

  exec { 'scanner-step2':
    command => 'unzip sonar-scanner-cli-3.0.3.778-linux.zip',
    cwd => '/root',
    creates => "/opt/sonar/bin/sonar-scanner",
  } ->

  exec { 'scanner-step3':
    command => 'mv /root/sonar-scanner-3.0.3.778-linux /opt/sonar',
    creates => "/opt/sonar/bin/sonar-scanner",
  } ->

  exec { 'scanner-step4':
    command => 'rm -f /root/sonar-scanner-3.0.3.778-linux.zip',
    onlyif => 'test -f /root/sonar-scanner-cli-3.0.3.778-linux.zip'
  }
}

# == Class: pm::ci::cidoc
#
# Prepare vhost doc for project
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::ci::cidoc {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  ensure_packages(['php-dompdf'])

  exec {'pear-phpdoc-channel':
    command => 'pear channel-discover pear.phpdoc.org',
    creates => '/usr/bin/phpdoc',
    require => Package['php-pear']
  } ->

  exec {'pear-phpdoc':
    command => 'pear install phpdoc/phpDocumentor',
    creates => '/usr/bin/phpdoc'
  }

  $docuri = hiera('docuri', 'pmdoc.nextdeploy.local')
  $isweb = hiera('iswebserver', 0)

  if $isweb == 1 {
    apache::vhost { "${docuri}":
      vhost_name => "${docuri}",
      port => '8080',
      ip => '127.0.0.1',
      override => ["All"],
      options => ['FollowSymLinks'],

      aliases => [
        { alias => '/robots.txt', path => '/var/www/robots.txt' },
      ],
      ensure => present,
      docroot_owner => 'modem',
      docroot_group => 'www-data',
      docroot => "/var/www/pm_doc",
      directories => [ { path => "/var/www/pm_doc",
                         allow_override => ["All"],
                         options => ['Indexes'] } ],
      require => [
        File['/etc/apache2/conf.d/tt.conf'],
        Exec['touchdeploygit']
      ],
      before => Service['varnish']
    }
  }
}

# == Class: pm::ci::ciw3af
#
# Prepare security audit
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::ci::ciw3af {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"

  ensure_packages(['python-pip', 'python-lxml', 'python-scapy', 'python-dev', 'python-setuptools'])

  exec {'pybloomfiltermmap-package':
    command => 'easy_install pybloomfiltermmap==0.3.14',
    creates => '/home/modem/.w3af_install'
  } ->

  exec {'pip-update':
    command => 'pip install --upgrade pip',
    creates => '/opt/w3af/w3af_console'
  } ->

  exec {'w3af-clone':
    command => 'git clone https://github.com/andresriancho/w3af.git',
    cwd => '/opt',
    creates => '/opt/w3af/w3af_console'
  } ->

  exec {'w3af-prerequisite':
    command => '/opt/w3af/./w3af_console || /tmp/./w3af_dependency_install.sh',
    cwd => '/opt',
    creates => '/home/modem/.w3af_install'
  } ->

  exec {'w3af-chown':
    command => 'chown -R jenkins: /opt/w3af',
    creates => '/home/modem/.w3af_install'
  } ->

  file {'/var/lib/jenkins/.w3af':
    ensure => directory,
    owner => 'jenkins'
  } ->

  file {'/var/lib/jenkins/.w3af/startup.conf':
    content => '[STARTUP_CONFIG]
auto-update = true
frequency = D
last-update =
last-commit =
accepted-disclaimer = true',
    owner => 'jenkins'
  } ->

  exec {'w3af-touchinstall':
    command => 'touch /home/modem/.w3af_install',
    creates => '/home/modem/.w3af_install'
  }
}
