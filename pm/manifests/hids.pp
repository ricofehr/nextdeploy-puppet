# == Class: pm::hids::agent
#
# Install ossec agent for send security alerts
#
#
# === Authors
#
# Eric Fehr <eric.fehr@publicis-modem.fr>
#
class pm::hids::agent {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", "/opt/bin" ] }
  
  $ossecip = hiera('ossecip', '')

  class { "ossec::client":
    ossec_server_ip => "${ossecip}",
    ossec_active_response => false,
  } ->

  exec { 'authclient':
    command => "/var/ossec/bin/agent-auth -m ${ossecip} -p 1515",
    unless => 'test -f /root/.ossecinstall'
  } ->

  exec { 'touchossecinstall':
    command => 'touch /root/.ossecinstall',
    unless => 'test -f /root/.ossecinstall'
  }
}