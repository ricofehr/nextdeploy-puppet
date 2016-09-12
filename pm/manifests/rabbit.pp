# == Class: pm::rabbit
#
# Install rabbitmq with help of official module
#
#
# === Authors
#
# Eric Fehr <ricofehr@nextdeploy.io>
#
class pm::rabbit {
  #rabbit setting
  class { 'rabbitmq':
    package_gpg_key => "https://www.rabbitmq.com/rabbitmq-release-signing-key.asc"
  }

  #create_resources ('rabbitmq_user', hiera('rabbitmq_user', []))
  #create_resources ('rabbitmq_user_permissions', hiera('rabbitmq_user_permissions', []))
}
