mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
}

variables {
  realm            = "my-realm"
  id               = "test-client"
  access_type      = "CONFIDENTIAL"
}

run "with_audience_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "audience-mapper"
      type = "audience"
      audience = {
        includedClient   = "target-client"
        addToIdToken     = true
        addToAccessToken = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_audience_protocol_mapper.this) == 1
    error_message = "Expected exactly one audience protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_audience_protocol_mapper.this["audience-mapper"].name == "audience-mapper"
    error_message = "Expected mapper name to be 'audience-mapper'."
  }
}

run "with_audience_resolve_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name            = "audience-resolve"
      type            = "audienceResolve"
      audienceResolve = {}
    }]
  }

  assert {
    condition     = length(keycloak_openid_audience_resolve_protocol_mapper.this) == 1
    error_message = "Expected exactly one audience resolve protocol mapper to be created."
  }
}

run "with_full_name_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "full-name"
      type = "fullName"
      fullName = {
        addToIdToken     = true
        addToAccessToken = true
        addToUserinfo    = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_full_name_protocol_mapper.this) == 1
    error_message = "Expected exactly one full name protocol mapper to be created."
  }
}

run "with_group_membership_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "groups"
      type = "groupMembership"
      groupMembership = {
        claimName        = "groups"
        fullPath         = true
        addToIdToken     = true
        addToAccessToken = true
        addToUserinfo    = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_group_membership_protocol_mapper.this) == 1
    error_message = "Expected exactly one group membership protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_group_membership_protocol_mapper.this["groups"].claim_name == "groups"
    error_message = "Expected claim_name to be 'groups'."
  }
}

run "with_hardcoded_claim_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "hardcoded-claim"
      type = "hardcodedClaim"
      hardcodedClaim = {
        name             = "custom_claim"
        value            = "custom_value"
        valueType        = "String"
        addToIdToken     = true
        addToAccessToken = true
        addToUserinfo    = false
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_hardcoded_claim_protocol_mapper.this) == 1
    error_message = "Expected exactly one hardcoded claim protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_hardcoded_claim_protocol_mapper.this["hardcoded-claim"].claim_name == "custom_claim"
    error_message = "Expected claim_name to be 'custom_claim'."
  }
}

run "with_hardcoded_role_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "hardcoded-role"
      type = "hardcodedRole"
      hardcodedRole = {
        name = "example-role"
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_hardcoded_role_protocol_mapper.this) == 1
    error_message = "Expected exactly one hardcoded role protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_hardcoded_role_protocol_mapper.this["hardcoded-role"].role_id == "example-role"
    error_message = "Expected role_id to be 'example-role'."
  }
}

run "with_user_attribute_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "user-attribute"
      type = "userAttribute"
      userAttribute = {
        name             = "department"
        claimName        = "dept"
        valueType        = "String"
        addToIdToken     = true
        addToAccessToken = true
        addToUserinfo    = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_user_attribute_protocol_mapper.this) == 1
    error_message = "Expected exactly one user attribute protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_user_attribute_protocol_mapper.this["user-attribute"].user_attribute == "department"
    error_message = "Expected user_attribute to be 'department'."
  }

  assert {
    condition     = keycloak_openid_user_attribute_protocol_mapper.this["user-attribute"].claim_name == "dept"
    error_message = "Expected claim_name to be 'dept'."
  }
}

run "with_user_property_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "email"
      type = "userProperty"
      userProperty = {
        name             = "email"
        claimName        = "email"
        valueType        = "String"
        addToIdToken     = true
        addToAccessToken = false
        addToUserinfo    = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_user_property_protocol_mapper.this) == 1
    error_message = "Expected exactly one user property protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_user_property_protocol_mapper.this["email"].user_property == "email"
    error_message = "Expected user_property to be 'email'."
  }
}

run "with_user_realm_role_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "realm-roles"
      type = "userRealmRole"
      userRealmRole = {
        claimName        = "realm_roles"
        multivalued      = true
        addToIdToken     = true
        addToAccessToken = true
        addToUserinfo    = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_user_realm_role_protocol_mapper.this) == 1
    error_message = "Expected exactly one user realm role protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_user_realm_role_protocol_mapper.this["realm-roles"].claim_name == "realm_roles"
    error_message = "Expected claim_name to be 'realm_roles'."
  }
}

run "with_user_client_role_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "client-roles"
      type = "userClientRole"
      userClientRole = {
        claimName               = "client_roles"
        clientIdForRoleMappings = "my-client"
        multivalued             = true
        addToIdToken            = true
        addToAccessToken        = true
        addToUserinfo           = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_user_client_role_protocol_mapper.this) == 1
    error_message = "Expected exactly one user client role protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_user_client_role_protocol_mapper.this["client-roles"].claim_name == "client_roles"
    error_message = "Expected claim_name to be 'client_roles'."
  }
}

run "with_user_session_note_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "session-note"
      type = "userSessionNote"
      userSessionNote = {
        name             = "session_state"
        claimName        = "session_state"
        valueType        = "String"
        addToIdToken     = true
        addToAccessToken = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_user_session_note_protocol_mapper.this) == 1
    error_message = "Expected exactly one user session note protocol mapper to be created."
  }

  assert {
    condition     = keycloak_openid_user_session_note_protocol_mapper.this["session-note"].session_note == "session_state"
    error_message = "Expected session_note to be 'session_state'."
  }
}

run "with_sub_mapper" {
  command = plan
  variables {
    protocol_mappers = [{
      name = "subject"
      type = "sub"
      sub = {
        addToAccessToken        = true
        addToTokenIntrospection = true
      }
    }]
  }

  assert {
    condition     = length(keycloak_openid_sub_protocol_mapper.this) == 1
    error_message = "Expected exactly one sub protocol mapper to be created."
  }
}

run "with_multiple_mappers" {
  command = plan
  variables {
    protocol_mappers = [
      {
        name = "full-name"
        type = "fullName"
        fullName = {
          addToIdToken     = true
          addToAccessToken = true
          addToUserinfo    = true
        }
      },
      {
        name = "groups"
        type = "groupMembership"
        groupMembership = {
          claimName        = "groups"
          fullPath         = false
          addToIdToken     = true
          addToAccessToken = true
          addToUserinfo    = true
        }
      },
      {
        name = "email"
        type = "userProperty"
        userProperty = {
          name             = "email"
          claimName        = "email"
          addToIdToken     = true
          addToAccessToken = true
          addToUserinfo    = true
        }
      }
    ]
  }

  assert {
    condition     = length(keycloak_openid_full_name_protocol_mapper.this) == 1
    error_message = "Expected exactly one full name mapper."
  }

  assert {
    condition     = length(keycloak_openid_group_membership_protocol_mapper.this) == 1
    error_message = "Expected exactly one group membership mapper."
  }

  assert {
    condition     = length(keycloak_openid_user_property_protocol_mapper.this) == 1
    error_message = "Expected exactly one user property mapper."
  }
}
