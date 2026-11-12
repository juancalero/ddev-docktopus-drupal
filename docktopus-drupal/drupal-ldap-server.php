<?php
// Creates the LDAP server entity (ldap_servers module) connected to the
// OpenLDAP service from ddev-docktopus-ldap. Idempotent:
//ddev-generated

if (!\Drupal::moduleHandler()->moduleExists('ldap_servers')) {
  echo "ldap_servers is not enabled; skipping.\n";
  exit(0);
}

$storage = \Drupal::entityTypeManager()->getStorage('ldap_server');

if ($storage->loadByProperties(['id' => 'openldap'])) {
  echo "ldap_server 'openldap' already exists.\n";
  exit(0);
}

$storage->create([
  'id' => 'openldap',
  'label' => 'OpenLDAP (docktopus)',
  'status' => TRUE,
  'type' => 'default',
  'address' => 'openldap',
  'port' => 389,
  'encryption' => 'none',
  'bind_method' => 'service_account',
  'binddn' => 'cn=admin,dc=miempresa,dc=local',
  'bindpw' => 'admin',
  'basedn' => ['dc=miempresa,dc=local'],
  'user_attr' => 'cn',
  'mail_attr' => 'mail',
  'unique_persistent_attr' => 'dn',
  'unique_persistent_attr_dn_check' => TRUE,
])->save();

echo "ldap_server 'openldap' created.\n";
echo "Review the connection and authentication settings at /admin/config/people/ldap.\n";
