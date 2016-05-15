
# == Class: pm::monitor::collect
#
# Collect some sensors from the node
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
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
   reportbycpu => false,
   valuespercentage => true,
  } ->

  class { 'collectd::plugin::df':
   mountpoints    => ['/u'],
   fstypes        => ['nfs','tmpfs','autofs','gpfs','proc','devpts'],
   ignoreselected => true,
  } ->

  class { 'collectd::plugin::disk':
   disks          => ['vda1'],
   udevnameattr   => 'DM_NAME',
  } ->

  class { 'collectd::plugin::interface':
    interfaces     => ['eth0'],
  } ->

  class { 'collectd::plugin::load': } ->

  class { 'collectd::plugin::processes': } ->

  class { 'collectd::plugin::memory': } ->

  class { 'collectd::plugin::snmp': } ->

  class { 'collectd::plugin::uptime': } ->

  class { 'collectd::plugin::users': } ->

  class { 'collectd::plugin::swap':
    reportbydevice => false,
    reportbytes    => true
  } ->

  class { 'collectd::plugin::syslog':
    log_level => 'warning'
  }

}


# == Class: pm::monitor::collect::apache
#
# Configure collectd plugn for apache
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::monitor::collect::apache {
  class { 'collectd::plugin::apache':
   instances => {
    'apache8080' => {
      'url' => 'http://localhost:8080/server-status?auto'
    },
   },
  }
}

# == Class: pm::monitor::collect::varnish
#
# Configure collectd plugn for varnish
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::monitor::collect::varnish {
  class { 'collectd::plugin::varnish':
    instances => {
      'instanceName' => {
        'CollectCache' => 'true',
        'CollectBackend' => 'true',
        'CollectConnections' => 'true',
        'CollectSHM' => 'true',
        'CollectESI' => 'false',
        'CollectFetch' => 'true',
        'CollectHCB' => 'false',
        'CollectTotals' => 'true',
        'CollectWorkers' => 'true',
      }
    }
  } ->

  class { 'collectd::plugin::tcpconns':
    localports  => ['80'],
    listening   => true,
  }
}

# == Class: pm::monitor::collect::redis
#
# Configure collectd plugin for redis
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::monitor::collect::redis {
  class { '::collectd::plugin::redis':
    nodes => {
      'node1' => {
        'host'     => 'localhost',
      }
    }
  }
 }

# == Class: pm::monitor::collect::mysql
#
# Configure collectd plugin for mysql
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::monitor::collect::mysql {
  collectd::plugin::mysql::database { 'server':
    host        => 'localhost',
    username    => 'root',
    password    => '',
    port        => '3306',
    masterstats => false,
  }
}
