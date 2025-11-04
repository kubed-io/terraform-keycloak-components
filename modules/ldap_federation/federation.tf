resource "keycloak_ldap_user_federation" "this" {

  # basic settings
  name     = local.name
  realm_id = data.keycloak_realm.this.id
  enabled  = var.enabled

  # server connection details
  vendor             = var.vendor
  bind_dn            = var.bind_dn
  bind_credential    = var.bind_credential
  start_tls          = var.start_tls
  use_truststore_spi = var.use_truststore_spi
  connection_url     = var.connection_url
  connection_timeout = var.connection_timeout
  read_timeout       = var.read_timeout

  # User settings
  username_ldap_attribute         = local.user_mapper.usernameAttribute
  rdn_ldap_attribute              = local.user_mapper.rdnAttribute
  uuid_ldap_attribute             = local.user_mapper.uuidAttribute
  user_object_classes             = local.user_mapper.objectClasses
  users_dn                        = local.user_mapper.baseDn
  search_scope                    = local.user_mapper.searchScope
  custom_user_search_filter       = local.user_mapper.searchFilter
  trust_email                     = local.user_mapper.trustEmail
  validate_password_policy        = local.user_mapper.validatePasswordPolicy
  use_password_modify_extended_op = local.user_mapper.usePasswordModifyExtendedOP
  edit_mode                       = local.user_mapper.mode

  # Sync settings
  import_enabled      = var.sync_settings.importEnabled
  sync_registrations  = var.sync_settings.syncRegistrations
  changed_sync_period = var.sync_settings.changeSyncPeriod
  full_sync_period    = var.sync_settings.fullSyncPeriod
  batch_size_for_sync = var.sync_settings.batchSize
  pagination          = var.sync_settings.pagination

}
