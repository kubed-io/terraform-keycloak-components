resource "keycloak_openid_audience_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "audience"
  }
  realm_id                 = data.keycloak_realm.this.id
  client_id                = keycloak_openid_client.this.id
  name                     = each.value.name
  included_client_audience = each.value.audience.includedClient
  included_custom_audience = each.value.audience.includedCustom
  add_to_id_token          = each.value.audience.addToIdToken
  add_to_access_token      = each.value.audience.addToAccessToken
}

resource "keycloak_openid_audience_resolve_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "audienceResolve"
  }
  realm_id  = data.keycloak_realm.this.id
  client_id = keycloak_openid_client.this.id
  name      = each.value.name
}

resource "keycloak_openid_full_name_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "fullName"
  }
  realm_id            = data.keycloak_realm.this.id
  client_id           = keycloak_openid_client.this.id
  name                = each.value.name
  add_to_id_token     = each.value.fullName.addToIdToken
  add_to_access_token = each.value.fullName.addToAccessToken
  add_to_userinfo     = each.value.fullName.addToUserinfo
}

resource "keycloak_openid_group_membership_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "groupMembership"
  }
  realm_id            = data.keycloak_realm.this.id
  client_id           = keycloak_openid_client.this.id
  name                = each.value.name
  claim_name          = each.value.groupMembership.claimName
  full_path           = each.value.groupMembership.fullPath
  add_to_id_token     = each.value.groupMembership.addToIdToken
  add_to_access_token = each.value.groupMembership.addToAccessToken
  add_to_userinfo     = each.value.groupMembership.addToUserinfo
}

resource "keycloak_openid_hardcoded_claim_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "hardcodedClaim"
  }
  realm_id            = data.keycloak_realm.this.id
  client_id           = keycloak_openid_client.this.id
  name                = each.value.name
  claim_name          = each.value.hardcodedClaim.name
  claim_value         = each.value.hardcodedClaim.value
  claim_value_type    = each.value.hardcodedClaim.valueType
  add_to_access_token = each.value.hardcodedClaim.addToAccessToken
  add_to_id_token     = each.value.hardcodedClaim.addToIdToken
  add_to_userinfo     = each.value.hardcodedClaim.addToUserinfo
}

resource "keycloak_openid_hardcoded_role_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "hardcodedRole"
  }
  realm_id  = data.keycloak_realm.this.id
  client_id = keycloak_openid_client.this.id
  name      = each.value.name
  role_id   = each.value.hardcodedRole.name
}

resource "keycloak_openid_sub_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "sub"
  }
  realm_id                   = data.keycloak_realm.this.id
  client_id                  = keycloak_openid_client.this.id
  name                       = each.value.name
  add_to_access_token        = each.value.sub.addToAccessToken
  add_to_token_introspection = each.value.sub.addToTokenIntrospection
}

resource "keycloak_openid_user_attribute_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "userAttribute"
  }
  realm_id             = data.keycloak_realm.this.id
  client_id            = keycloak_openid_client.this.id
  name                 = each.value.name
  user_attribute       = each.value.userAttribute.name
  claim_name           = each.value.userAttribute.claimName
  claim_value_type     = each.value.userAttribute.valueType
  aggregate_attributes = each.value.userAttribute.aggregate
  multivalued          = each.value.userAttribute.multivalued
  add_to_id_token      = each.value.userAttribute.addToIdToken
  add_to_access_token  = each.value.userAttribute.addToAccessToken
  add_to_userinfo      = each.value.userAttribute.addToUserinfo
}

resource "keycloak_openid_user_client_role_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "userClientRole"
  }
  realm_id                    = data.keycloak_realm.this.id
  client_id                   = keycloak_openid_client.this.id
  name                        = each.value.name
  claim_name                  = each.value.userClientRole.claimName
  client_id_for_role_mappings = each.value.userClientRole.clientIdForRoleMappings
  client_role_prefix          = each.value.userClientRole.prefix
  claim_value_type            = each.value.userClientRole.valueType
  multivalued                 = each.value.userClientRole.multivalued
  add_to_id_token             = each.value.userClientRole.addToIdToken
  add_to_access_token         = each.value.userClientRole.addToAccessToken
  add_to_userinfo             = each.value.userClientRole.addToUserinfo
}

resource "keycloak_openid_user_property_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "userProperty"
  }
  realm_id            = data.keycloak_realm.this.id
  client_id           = keycloak_openid_client.this.id
  name                = each.value.name
  user_property       = each.value.userProperty.name
  claim_name          = each.value.userProperty.claimName
  claim_value_type    = each.value.userProperty.valueType
  add_to_id_token     = each.value.userProperty.addToIdToken
  add_to_access_token = each.value.userProperty.addToAccessToken
  add_to_userinfo     = each.value.userProperty.addToUserinfo
}

resource "keycloak_openid_user_realm_role_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "userRealmRole"
  }
  realm_id                   = data.keycloak_realm.this.id
  client_id                  = keycloak_openid_client.this.id
  name                       = each.value.name
  claim_name                 = each.value.userRealmRole.claimName
  realm_role_prefix          = each.value.userRealmRole.realmRolePrefix
  claim_value_type           = each.value.userRealmRole.valueType
  multivalued                = each.value.userRealmRole.multivalued
  add_to_id_token            = each.value.userRealmRole.addToIdToken
  add_to_access_token        = each.value.userRealmRole.addToAccessToken
  add_to_userinfo            = each.value.userRealmRole.addToUserinfo
  add_to_token_introspection = each.value.userRealmRole.addToTokenIntrospection
}

resource "keycloak_openid_user_session_note_protocol_mapper" "this" {
  for_each = {
    for mapper in var.protocol_mappers : mapper.name => mapper
    if mapper.type == "userSessionNote"
  }
  realm_id            = data.keycloak_realm.this.id
  client_id           = keycloak_openid_client.this.id
  name                = each.value.name
  session_note        = each.value.userSessionNote.name
  claim_name          = each.value.userSessionNote.claimName
  claim_value_type    = each.value.userSessionNote.valueType
  add_to_id_token     = each.value.userSessionNote.addToIdToken
  add_to_access_token = each.value.userSessionNote.addToAccessToken
}
