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
  # if $::operatingsystem == 'Ubuntu' and $::lsbdistrelease == '14.04' and $version == '8' {
  #   $version = '7'
  # }
  #
  # # no java6 on debian 8
  # if $::operatingsystem == 'Debian' and versioncmp($::operatingsystemrelease, '8') >= 0 and $version == '6' {
  #   $version = '7'
  # }

  if $version == '6' {
    $version_hash = 'default'
    $version_update = 'default'
    $version_build = 'default'
  }

  if $version == '7' {
    $version_hash = 'default'
    $version_update = 'default'
    $version_build = 'default'
  }

  if $version == '8' {
    $version_hash = 'd54c1d3a095b4ff2b6607d096fa80163'
    $version_update = '131'
    $version_build = '11'
  }

  class { 'jdk_oracle':
    version => $version,
    version_hash => $version_hash,
    version_update => $version_update,
    version_build => $version_build
  } ->

  class { 'maven::maven':
     version => "3.2.5",
     before => File['/usr/local/bin/mvn.sh']
  }
}
