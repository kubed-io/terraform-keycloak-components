mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
  mock_data "keycloak_user" {
    defaults = {
      id = "user-id"
    }
  }
  mock_data "keycloak_group" {
    defaults = {
      id = "group-id"
    }
  }
  mock_data "keycloak_role" {
    defaults = {
      id = "role-id"
    }
  }
  mock_data "keycloak_openid_client" {
    defaults = {
      id = "other-client-id"
    }
  }
  mock_data "keycloak_openid_client_scope" {
    defaults = {
      id = "client-scope-id"
    }
  }
}

variables {
  realm        = "my-realm"
  id           = "billing"
  access_type  = "CONFIDENTIAL"
  capabilities = { serviceAccountsEnabled = true }
}

run "enabled_without_contents" {
  command = plan
  variables {
    authorization = { policyEnforcementMode = "ENFORCING" }
  }

  assert {
    condition = (
      length(keycloak_openid_client_authorization_scope.this) == 0
      && length(keycloak_openid_client_authorization_resource.this) == 0
      && length(keycloak_openid_client_role_policy.this) == 0
      && length(keycloak_openid_client_authorization_permission.this) == 0
    )
    error_message = "Expected no authorization contents when none are listed."
  }
}

run "scopes_and_resources" {
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      scopes = [
        { name = "view" },
        { name = "edit", displayName = "Edit" },
      ]
      resources = [{
        name   = "invoices"
        type   = "urn:billing:invoice"
        uris   = ["/invoices/*"]
        scopes = ["view", "edit"]
      }]
    }
  }

  assert {
    condition     = keycloak_openid_client_authorization_scope.this["edit"].display_name == "Edit"
    error_message = "Expected each scope to be created by name."
  }

  assert {
    condition     = keycloak_openid_client_authorization_resource.this["invoices"].resource_server_id == keycloak_openid_client.this.resource_server_id
    error_message = "Expected the resource on this client's resource server."
  }

  assert {
    condition     = keycloak_openid_client_authorization_resource.this["invoices"].scopes == toset(["view", "edit"])
    error_message = "Expected the resource to carry its scopes by name."
  }

  assert {
    condition     = keycloak_openid_client_authorization_resource.this["invoices"].uris == toset(["/invoices/*"])
    error_message = "Expected the resource URIs."
  }
}

run "policies_by_type_with_name_lookups" {
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      policies = [
        {
          name = "admins"
          type = "role"
          role = {
            roles = [
              { name = "admin", required = true },
              { name = "editor", client = "grafana" },
            ]
          }
        },
        {
          name  = "staff"
          type  = "group"
          group = { groups = [{ path = "/staff", extendChildren = true }] }
        },
        {
          name = "alice-only"
          type = "user"
          user = { users = ["alice"] }
        },
        {
          name   = "from-n8n"
          type   = "client"
          client = { clients = ["n8n"] }
        },
        {
          name        = "has-mcp-scope"
          type        = "clientScope"
          clientScope = { scopes = [{ name = "mcp", required = true }] }
        },
        {
          name = "business-hours"
          type = "time"
          time = { hour = 9, hourEnd = 17 }
        },
        {
          name  = "kubed-mail"
          type  = "regex"
          regex = { targetClaim = "email", pattern = ".*@mail\\.kubed\\.io$" }
        },
        {
          name      = "admins-in-hours"
          type      = "aggregate"
          logic     = "POSITIVE"
          aggregate = { policies = ["admins", "business-hours"] }
        },
      ]
    }
  }

  assert {
    condition = (
      keycloak_openid_client_role_policy.this["admins"].role
      == toset([{ id = "role-id", required = true }, { id = "role-id", required = false }])
    )
    error_message = "Expected both roles looked up by name (both mock to role-id), with required defaulting to false."
  }

  assert {
    condition     = data.keycloak_role.authz["grafana/editor"].client_id == "other-client-id"
    error_message = "Expected a client role to be looked up under its client's internal ID."
  }

  assert {
    condition     = keycloak_openid_client_group_policy.this["staff"].groups[0].id == "group-id" && keycloak_openid_client_group_policy.this["staff"].groups[0].path == "/staff"
    error_message = "Expected the group looked up by path."
  }

  assert {
    condition     = keycloak_openid_client_group_policy.this["staff"].decision_strategy == "UNANIMOUS"
    error_message = "Expected the decision strategy to default to UNANIMOUS."
  }

  assert {
    condition     = keycloak_openid_client_user_policy.this["alice-only"].users == toset(["user-id"])
    error_message = "Expected the user looked up by username."
  }

  assert {
    condition     = keycloak_openid_client_client_policy.this["from-n8n"].clients == toset(["other-client-id"])
    error_message = "Expected the client looked up by clientId."
  }

  assert {
    condition     = one(keycloak_openid_client_authorization_client_scope_policy.this["has-mcp-scope"].scope).id == "client-scope-id"
    error_message = "Expected the client scope looked up by name."
  }

  assert {
    condition     = keycloak_openid_client_time_policy.this["business-hours"].hour == "9"
    error_message = "Expected numeric time fields to reach the provider as strings."
  }

  assert {
    condition     = keycloak_openid_client_regex_policy.this["kubed-mail"].target_claim == "email"
    error_message = "Expected the regex policy's claim."
  }

  assert {
    condition = keycloak_openid_client_aggregate_policy.this["admins-in-hours"].policies == toset([
      keycloak_openid_client_role_policy.this["admins"].id,
      keycloak_openid_client_time_policy.this["business-hours"].id,
    ])
    error_message = "Expected the aggregate to reference its policies' IDs."
  }
}

run "permissions_reference_by_name" {
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      scopes                = [{ name = "view" }, { name = "edit" }]
      resources             = [{ name = "invoices", scopes = ["view", "edit"] }]
      policies = [
        { name = "readers", type = "user", user = { users = ["alice"] } },
        { name = "writers", type = "user", user = { users = ["bob"] } },
      ]
      permissions = [
        {
          name      = "read-invoices"
          resources = ["invoices"]
          policies  = ["readers"]
        },
        {
          name             = "edit-invoices"
          type             = "scope"
          resources        = ["invoices"]
          scopes           = ["edit"]
          policies         = ["writers", "readers"]
          decisionStrategy = "AFFIRMATIVE"
        },
      ]
    }
  }

  assert {
    condition     = keycloak_openid_client_authorization_permission.this["read-invoices"].type == "resource"
    error_message = "Expected a permission to default to resource-based."
  }

  assert {
    condition     = keycloak_openid_client_authorization_permission.this["read-invoices"].resources == toset([keycloak_openid_client_authorization_resource.this["invoices"].id])
    error_message = "Expected the resource referenced by its ID."
  }

  assert {
    condition     = keycloak_openid_client_authorization_permission.this["edit-invoices"].scopes == toset([keycloak_openid_client_authorization_scope.this["edit"].id])
    error_message = "Expected the scope referenced by its ID."
  }

  assert {
    condition = keycloak_openid_client_authorization_permission.this["edit-invoices"].policies == toset([
      keycloak_openid_client_user_policy.this["writers"].id,
      keycloak_openid_client_user_policy.this["readers"].id,
    ])
    error_message = "Expected the policies referenced by their IDs."
  }

  assert {
    condition     = keycloak_openid_client_authorization_permission.this["edit-invoices"].decision_strategy == "AFFIRMATIVE"
    error_message = "Expected the decision strategy to pass through."
  }
}

run "own_client_role_is_looked_up_under_this_client" {
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      policies = [{
        name = "billing-admins"
        type = "role"
        role = { roles = [{ name = "admin", client = "billing" }] }
      }]
    }
  }

  assert {
    condition     = data.keycloak_role.authz["billing/admin"].client_id == keycloak_openid_client.this.id
    error_message = "Expected a role of this client to be looked up under this client, which is not a data lookup."
  }

  assert {
    condition     = length(data.keycloak_openid_client.authz) == 0
    error_message = "Expected no lookup of this client by clientId; it may not exist yet."
  }
}
