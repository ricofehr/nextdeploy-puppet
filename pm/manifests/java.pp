# == Class: pm::java
#
# Install java with help of official module
#
# === Parameters
#
# [*version*]
#   Version to install (6,7,8).
#   Default: 7
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::java ($version = '7') {
  
  # no java8 on ubuntu 14.04
  if $::operatingsystem == 'Ubuntu' and $::lsbdistrelease == '14.04' and $version == '8' {
    $version = '7'
  }

  # no java6 on debian 8
  if $::operatingsystem == 'Debian' and versioncmp($::operatingsystemrelease, '8') >= 0 and $version == '6' {
    $version = '7'
  }

  #rabbit setting
  class { '::java':
    distribution => 'jdk',
    package => "openjdk-${version}-jdk",
    java_alternative => "java-1.${version}.0-openjdk-${::architecture}",
    java_alternative_path => "/usr/lib/jvm/java-1.${version}.0-openjdk-${::architecture}/bin/java"
  } ->

  class { 'maven::maven':
     version => "3.2.5",
  }
}
