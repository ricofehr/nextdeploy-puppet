
# == Class: pm::monitor::collect
#
# Collect some sensors from the node
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::monitor::collect {
 $influxip = hiera('influxip')

 class { 'collectd':
  purge           => true,
  recurse         => true,
  purge_config    => true,
  collectd_hostname => "${clientcert}",
  fqdnlookup => false,
  require => Package['curl'],
 } ->
 
 collectd::plugin::network::server{"${influxip}": 
    port => 2004
 } ->
 
 class { 'collectd::plugin::conntrack': } ->
 
 class { 'collectd::plugin::cpu':
  reportbystate => true,
  reportbycpu => true,
  valuespercentage => true,
 } ->
 
 class { 'collectd::plugin::df':
  mountpoints    => ['/u'],
  fstypes        => ['nfs','tmpfs','autofs','gpfs','proc','devpts'],
  ignoreselected => true,
 } ->
 
 class { 'collectd::plugin::disk':
  disks          => ['/^dm/'],
  ignoreselected => true,
  udevnameattr   => 'DM_NAME',
 } ->
 
 class { 'collectd::plugin::interface': } ->
 
 class { 'collectd::plugin::load': } ->

 class { 'collectd::plugin::processes': } ->

 class { 'collectd::plugin::memory': } ->

 class { 'collectd::plugin::snmp': } ->

 class { 'collectd::plugin::uptime': } ->

 class { 'collectd::plugin::users': }
}