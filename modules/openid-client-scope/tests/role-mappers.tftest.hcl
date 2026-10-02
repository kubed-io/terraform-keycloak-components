mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
  mock_data "keycloak_openid_client" {
    defaults = {
      id = "buz-uuid"
    }
  }
  mock_data "keycloak_role" {
    defaults = {
      id = "role-uuid"
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
    condition     = length(keycloak_generic_role_mapper.this) == 0 && length(data.keycloak_openid_client.role_client) == 0
    error_message = "Expected no role mappings and no lookups when unset."
  }
}

run "realm_and_client_roles" {
  command = plan
  variables {
    roles = [
      { name = "foo" },
      { name = "bar", client = "buz" },
      { name = "qux", client = "buz" },
    ]
  }

  assert {
    condition     = length(keycloak_generic_role_mapper.this) == 3
    error_message = "Expected one role mapping per role."
  }

  assert {
    condition     = data.keycloak_role.this["foo"].client_id == null && data.keycloak_role.this["foo"].name == "foo"
    error_message = "Expected a realm role lookup with no client."
  }

  assert {
    condition     = data.keycloak_role.this["buz/bar"].client_id == "buz-uuid" && data.keycloak_role.this["buz/bar"].name == "bar"
    error_message = "Expected the client role lookup to use the client's internal ID."
  }

  assert {
    condition     = length(data.keycloak_openid_client.role_client) == 1 && data.keycloak_openid_client.role_client["buz"].client_id == "buz"
    error_message = "Expected one client lookup per distinct client, by clientId."
  }

  assert {
    condition     = keycloak_generic_role_mapper.this["buz/bar"].role_id == "role-uuid" && keycloak_generic_role_mapper.this["foo"].client_id == null
    error_message = "Expected the mapping on the scope with the looked-up role ID."
  }
}

run "same_name_realm_and_client_role" {
  command = plan
  variables {
    roles = [{ name = "admin" }, { name = "admin", client = "buz" }]
  }

  assert {
    condition     = length(keycloak_generic_role_mapper.this) == 2
    error_message = "Expected a realm role and a client role with the same name to both map."
  }
}

run "rejects_duplicates" {
  command = plan
  variables {
    roles = [{ name = "foo" }, { name = "foo" }]
  }
  expect_failures = [var.roles]
}
