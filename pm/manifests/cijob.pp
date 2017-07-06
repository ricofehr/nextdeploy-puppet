define pm::cijob(
  $absolute = $name,
  $path,
  $envvars = [],
  $aliases = [],
  $framework,
  $clustering = 1,
  $rewrites = '',
  $publicfolder = '',
  $customvhost = ''
) {

  $docrootgit = hiera('docrootgit', '/var/www/html')
  $docroot = "${docrootgit}/${path}"
  $project = hiera('project', 'www.test.com')

  # Some jobs needs local endpoint
  file_line { "hosts-${path}":
    path => '/etc/hosts',
    line => "127.0.0.1 ${absolute}"
  }

  # Template uses:
  # - $docroot
  # - $docrootgit
  # - $project
  jenkins::job { "testunit-${path}":
    config => multitemplate("pm/jenkins/projects/${project}/testunit.xml.erb",
                            "pm/jenkins/testunit-${framework}.xml.erb",
                            "pm/jenkins/testunit.xml.erb"),
    ensure => 'present',
  }

  jenkins::job { "doc-${path}":
    config => multitemplate("pm/jenkins/projects/${project}/doc.xml.erb",
                            "pm/jenkins/doc-${framework}.xml.erb",
                            "pm/jenkins/doc.xml.erb"),
    ensure => 'present',
  }

  jenkins::job { "sonarqube-${path}":
    config => multitemplate("pm/jenkins/projects/${project}/sonarqube.xml.erb",
                            "pm/jenkins/sonarqube.xml.erb"),
    ensure => 'present',
  }
  #
  jenkins::job { "securityscan-${path}":
     config => multitemplate("pm/jenkins/projects/${project}/securityscan.xml.erb",
                             "pm/jenkins/securityscan.xml.erb"),
     ensure => 'present',
  }
}
