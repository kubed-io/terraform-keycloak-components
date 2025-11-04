resource "keycloak_ldap_user_attribute_mapper" "this" {
  for_each = {
    for mapper in var.mappers : coalesce(mapper.name, mapper.type) => mapper
    if mapper.type == "userAttribute"
  }
  realm_id                    = data.keycloak_realm.this.id
  ldap_user_federation_id     = keycloak_ldap_user_federation.this.id
  name                        = each.key
  user_model_attribute        = each.value.userAttribute.userModelAttribute
  ldap_attribute              = each.value.userAttribute.ldapAttribute
  read_only                   = each.value.userAttribute.readOnly
  always_read_value_from_ldap = each.value.userAttribute.alwaysReadValueFromLdap
  is_mandatory_in_ldap        = each.value.userAttribute.isMandatoryInLdap
  is_binary_attribute         = each.value.userAttribute.isBinaryAttribute
  attribute_default_value     = each.value.userAttribute.attributeDefaultValue
}

resource "keycloak_ldap_role_mapper" "this" {
  for_each = {
    for mapper in var.mappers : coalesce(mapper.name, mapper.type) => mapper
    if mapper.type == "role"
  }
  realm_id                       = data.keycloak_realm.this.id
  ldap_user_federation_id        = keycloak_ldap_user_federation.this.id
  name                           = each.key
  ldap_roles_dn                  = each.value.role.baseDn
  role_name_ldap_attribute       = each.value.role.nameAttribute
  role_object_classes            = each.value.role.objectClasses
  membership_ldap_attribute      = each.value.role.membershipAttribute
  membership_attribute_type      = each.value.role.membershipAttributeType
  membership_user_ldap_attribute = each.value.role.membershipUserAttribute
  roles_ldap_filter              = each.value.role.searchFilter
  mode                           = each.value.role.mode
  user_roles_retrieve_strategy   = each.value.role.userRolesRetrieveStrategy
  memberof_ldap_attribute        = each.value.role.memberofAttribute
  use_realm_roles_mapping        = each.value.role.useRealmRolesMapping
  client_id                      = each.value.role.clientId
}

resource "keycloak_ldap_group_mapper" "this" {
  for_each = {
    for mapper in var.mappers : coalesce(mapper.name, mapper.type) => mapper
    if mapper.type == "group"
  }
  realm_id                             = data.keycloak_realm.this.id
  ldap_user_federation_id              = keycloak_ldap_user_federation.this.id
  name                                 = each.key
  ldap_groups_dn                       = each.value.group.baseDn
  group_name_ldap_attribute            = each.value.group.nameAttribute
  preserve_group_inheritance           = each.value.group.preserveInheritance
  ignore_missing_groups                = each.value.group.ignoreMissing
  membership_ldap_attribute            = each.value.group.membershipAttribute
  membership_attribute_type            = each.value.group.membershipAttributeType
  membership_user_ldap_attribute       = each.value.group.membershipUserAttribute
  groups_ldap_filter                   = each.value.group.searchFilter
  mode                                 = each.value.group.mode
  user_roles_retrieve_strategy         = each.value.group.userRolesRetrieveStrategy
  memberof_ldap_attribute              = each.value.group.memberofAttribute
  mapped_group_attributes              = each.value.group.mappedAttributes
  drop_non_existing_groups_during_sync = each.value.group.dropNonExistingDuringSync
  group_object_classes                 = each.value.group.objectClasses
  groups_path                          = each.value.group.path
}

resource "keycloak_ldap_hardcoded_role_mapper" "this" {
  for_each = {
    for mapper in var.mappers : coalesce(mapper.name, mapper.type) => mapper
    if mapper.type == "hardcodedRole"
  }
  realm_id                = data.keycloak_realm.this.id
  ldap_user_federation_id = keycloak_ldap_user_federation.this.id
  name                    = each.key
  role                    = each.value.hardcodedRole.name
}

resource "keycloak_ldap_hardcoded_group_mapper" "this" {
  for_each = {
    for mapper in var.mappers : coalesce(mapper.name, mapper.type) => mapper
    if mapper.type == "hardcodedGroup"
  }
  realm_id                = data.keycloak_realm.this.id
  ldap_user_federation_id = keycloak_ldap_user_federation.this.id
  name                    = each.key
  group                   = each.value.hardcodedGroup.name
}

resource "keycloak_ldap_hardcoded_attribute_mapper" "this" {
  for_each = {
    for mapper in var.mappers : coalesce(mapper.name, mapper.type) => mapper
    if mapper.type == "hardcodedAttribute"
  }
  realm_id                = data.keycloak_realm.this.id
  ldap_user_federation_id = keycloak_ldap_user_federation.this.id
  name                    = each.key
  attribute_name          = each.value.hardcodedAttribute.name
  attribute_value         = each.value.hardcodedAttribute.value
}
