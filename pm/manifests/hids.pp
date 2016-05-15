# == Class: pm::hids::agent
#
# Install ossec agent for send security alerts
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::hids::agent {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }

  $ossecip = hiera('ossecip', '')
  $isprod = hiera('isprod', 0)

  if $isprod == 1 {
    class { "ossec::client":
      ossec_server_ip => "${ossecip}",
      ossec_active_response => false,
    }
  }
  else {
    package { 'ossec-hids-agent':
      ensure  => purged,
    }
  }
}