# Role mappers attached to this client. Two kinds (var.role_mappers[*].type):
#   ldap    → keycloak_ldap_role_mapper (cn=<role> children under baseDn → CLIENT roles
#             of THIS client; federation GUID resolved by name via the Admin REST API,
#             then force-synced to Keycloak — see role-sync.tf)
#   generic → keycloak_generic_client_role_mapper (add an existing role to this client's
#             scope mappings)
#
# The locals these read (ldap_mappers, generic_mappers, fed_guid) and the Admin API calls
# that back them live in main.tf.

# LDAP role mappers → CLIENT roles of THIS client. Because the mapper is bound to this
# client (client_id set), Keycloak requires use_realm_roles_mapping = false.
resource "keycloak_ldap_role_mapper" "this" {
  for_each = {
    for m in local.ldap_mappers :
    coalesce(m.name, m.type) => m
  }

  realm_id                = data.keycloak_realm.this.id
  ldap_user_federation_id = local.fed_guid[coalesce(each.value.ldap.federationId, var.realm)]
  name                    = each.key

  ldap_roles_dn                  = each.value.ldap.baseDn
  role_name_ldap_attribute       = each.value.ldap.nameAttribute
  role_object_classes            = each.value.ldap.objectClasses
  membership_ldap_attribute      = each.value.ldap.membershipAttribute
  membership_attribute_type      = each.value.ldap.membershipAttributeType
  membership_user_ldap_attribute = each.value.ldap.membershipUserAttribute
  user_roles_retrieve_strategy   = each.value.ldap.userRolesRetrieveStrategy
  memberof_ldap_attribute        = each.value.ldap.memberofAttribute
  mode                           = each.value.ldap.mode
  roles_ldap_filter              = each.value.ldap.searchFilter

  use_realm_roles_mapping = false
  client_id               = keycloak_openid_client.this.client_id
}

# Generic role mappers → add an existing role (by id) to THIS client's scope.
resource "keycloak_generic_role_mapper" "this" {
  for_each = {
    for m in local.generic_mappers :
    coalesce(m.name, m.type) => m
  }

  realm_id  = data.keycloak_realm.this.id
  client_id = keycloak_openid_client.this.id
  role_id   = each.value.generic.roleId
}
