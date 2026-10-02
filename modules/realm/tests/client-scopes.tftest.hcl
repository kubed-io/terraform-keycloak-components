mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

run "unset_leaves_keycloak_defaults" {
  command = plan

  assert {
    condition     = length(keycloak_realm_default_client_scopes.this) == 0 && length(keycloak_realm_optional_client_scopes.this) == 0
    error_message = "Expected no realm default scope resources when client_scopes is unset."
  }
}

run "default_and_optional" {
  command = plan
  variables {
    client_scopes = {
      default  = ["profile", "email"]
      optional = ["address", "phone"]
    }
  }

  assert {
    condition     = toset(keycloak_realm_default_client_scopes.this[0].default_scopes) == toset(["profile", "email"])
    error_message = "Expected the default client scopes to be passed through."
  }

  assert {
    condition     = toset(keycloak_realm_optional_client_scopes.this[0].optional_scopes) == toset(["address", "phone"])
    error_message = "Expected the optional client scopes to be passed through."
  }
}

run "only_optional" {
  command = plan
  variables {
    client_scopes = {
      optional = ["address"]
    }
  }

  assert {
    condition     = length(keycloak_realm_default_client_scopes.this) == 0 && length(keycloak_realm_optional_client_scopes.this) == 1
    error_message = "Expected only the optional scopes resource."
  }
}
