mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
}

variables {
  realm = "my-realm"
  name  = "mcp"
}

run "none_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_generic_role_mapper.this) == 0
    error_message = "Expected no role scope mappings when unset."
  }
}

run "one_per_role" {
  command = plan
  variables {
    roles = ["role-a", "role-b"]
  }

  assert {
    condition     = length(keycloak_generic_role_mapper.this) == 2
    error_message = "Expected one role scope mapping per role ID."
  }

  assert {
    condition     = keycloak_generic_role_mapper.this["role-a"].role_id == "role-a" && keycloak_generic_role_mapper.this["role-a"].client_id == null
    error_message = "Expected the mapping on the client scope with the given role ID."
  }
}
