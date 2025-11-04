mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
}

variables {
  realm       = "my-realm"
  id          = "test-client"
  access_type = "CONFIDENTIAL"
}

run "with_view_scope_permission" {
  command = plan
  variables {
    permissions = [{
      scope            = "view"
      policies         = ["policy-id-1", "policy-id-2"]
      description      = "View permission"
      decisionStrategy = "UNANIMOUS"
    }]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected permissions resource to be created."
  }

  assert {
    condition     = keycloak_openid_client_permissions.this[0].realm_id == "example-realm-id"
    error_message = "Expected permissions to use correct realm_id."
  }

  assert {
    condition     = keycloak_openid_client_permissions.this[0].client_id == keycloak_openid_client.this.id
    error_message = "Expected permissions to reference the client id."
  }
}

run "with_manage_scope_permission" {
  command = plan
  variables {
    permissions = [{
      scope       = "manage"
      policies    = ["policy-id-1"]
      description = "Manage permission"
    }]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected permissions resource to be created."
  }
}

run "with_configure_scope_permission" {
  command = plan
  variables {
    permissions = [{
      scope    = "configure"
      policies = ["policy-id-1"]
    }]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected permissions resource to be created."
  }
}

run "with_map_roles_scope_permission" {
  command = plan
  variables {
    permissions = [{
      scope    = "map-roles"
      policies = ["policy-id-1"]
    }]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected permissions resource to be created."
  }
}

run "with_map_roles_client_scope_permission" {
  command = plan
  variables {
    permissions = [{
      scope    = "map-roles-client-scope"
      policies = ["policy-id-1"]
    }]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected permissions resource to be created."
  }
}

run "with_map_roles_composite_scope_permission" {
  command = plan
  variables {
    permissions = [{
      scope    = "map-roles-composite"
      policies = ["policy-id-1"]
    }]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected permissions resource to be created."
  }
}

run "with_token_exchange_scope_permission" {
  command = plan
  variables {
    permissions = [{
      scope    = "token-exchange"
      policies = ["policy-id-1"]
    }]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected permissions resource to be created."
  }
}

run "with_multiple_permissions_same_scope" {
  command = plan
  variables {
    permissions = [
      {
        scope            = "view"
        policies         = ["view-policy-1"]
        description      = "View permission"
        decisionStrategy = "AFFIRMATIVE"
      },
      {
        scope            = "manage"
        policies         = ["manage-policy-1", "manage-policy-2"]
        description      = "Manage permission"
        decisionStrategy = "UNANIMOUS"
      },
      {
        scope    = "configure"
        policies = ["configure-policy-1"]
      }
    ]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected one permissions resource to be created."
  }
}

run "with_all_scope_types" {
  command = plan
  variables {
    permissions = [
      { scope = "view", policies = ["policy-1"] },
      { scope = "manage", policies = ["policy-2"] },
      { scope = "configure", policies = ["policy-3"] },
      { scope = "map-roles", policies = ["policy-4"] },
      { scope = "map-roles-client-scope", policies = ["policy-5"] },
      { scope = "map-roles-composite", policies = ["policy-6"] },
      { scope = "token-exchange", policies = ["policy-7"] }
    ]
  }

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 1
    error_message = "Expected permissions resource to be created with all scope types."
  }
}

run "without_permissions_variable" {
  command = plan

  assert {
    condition     = length(keycloak_openid_client_permissions.this) == 0
    error_message = "Expected no permissions resource when permissions variable is null."
  }
}

run "verify_dynamic_filtering_view" {
  command = plan
  variables {
    permissions = [
      { scope = "view", policies = ["view-policy"] },
      { scope = "manage", policies = ["manage-policy"] }
    ]
  }

  assert {
    condition     = length([for p in var.permissions : p if p.scope == "view"]) == 1
    error_message = "Expected view scope to be filtered correctly."
  }

  assert {
    condition     = length([for p in var.permissions : p if p.scope == "manage"]) == 1
    error_message = "Expected manage scope to be filtered correctly."
  }

  assert {
    condition     = length([for p in var.permissions : p if p.scope == "configure"]) == 0
    error_message = "Expected no configure scope in this test."
  }
}
