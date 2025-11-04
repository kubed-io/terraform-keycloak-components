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

run "with_default_scopes_only" {
  command = plan
  variables {
    scopes = {
      default = ["email", "profile", "roles"]
    }
  }

  assert {
    condition     = length(keycloak_openid_client_default_scopes.this) == 1
    error_message = "Expected default scopes resource to be created."
  }

  assert {
    condition     = length(keycloak_openid_client_default_scopes.this[0].default_scopes) == 3
    error_message = "Expected 3 default scopes."
  }

  assert {
    condition     = contains(keycloak_openid_client_default_scopes.this[0].default_scopes, "email")
    error_message = "Expected 'email' to be in default scopes."
  }

  assert {
    condition     = length(keycloak_openid_client_optional_scopes.this) == 0
    error_message = "Expected no optional scopes resource when only default scopes are specified."
  }
}

run "with_optional_scopes_only" {
  command = plan
  variables {
    scopes = {
      optional = ["address", "phone", "offline_access"]
    }
  }

  assert {
    condition     = length(keycloak_openid_client_optional_scopes.this) == 1
    error_message = "Expected optional scopes resource to be created."
  }

  assert {
    condition     = length(keycloak_openid_client_optional_scopes.this[0].optional_scopes) == 3
    error_message = "Expected 3 optional scopes."
  }

  assert {
    condition     = contains(keycloak_openid_client_optional_scopes.this[0].optional_scopes, "offline_access")
    error_message = "Expected 'offline_access' to be in optional scopes."
  }

  assert {
    condition     = length(keycloak_openid_client_default_scopes.this) == 0
    error_message = "Expected no default scopes resource when only optional scopes are specified."
  }
}

run "with_both_default_and_optional_scopes" {
  command = plan
  variables {
    scopes = {
      default  = ["email", "profile"]
      optional = ["address", "phone"]
    }
  }

  assert {
    condition     = length(keycloak_openid_client_default_scopes.this) == 1
    error_message = "Expected default scopes resource to be created."
  }

  assert {
    condition     = length(keycloak_openid_client_default_scopes.this[0].default_scopes) == 2
    error_message = "Expected 2 default scopes."
  }

  assert {
    condition     = length(keycloak_openid_client_optional_scopes.this) == 1
    error_message = "Expected optional scopes resource to be created."
  }

  assert {
    condition     = length(keycloak_openid_client_optional_scopes.this[0].optional_scopes) == 2
    error_message = "Expected 2 optional scopes."
  }

  assert {
    condition     = keycloak_openid_client_default_scopes.this[0].realm_id == "example-realm-id"
    error_message = "Expected default scopes to use correct realm_id."
  }

  assert {
    condition     = keycloak_openid_client_optional_scopes.this[0].realm_id == "example-realm-id"
    error_message = "Expected optional scopes to use correct realm_id."
  }

  assert {
    condition     = keycloak_openid_client_default_scopes.this[0].client_id == keycloak_openid_client.this.id
    error_message = "Expected default scopes to reference the client id."
  }

  assert {
    condition     = keycloak_openid_client_optional_scopes.this[0].client_id == keycloak_openid_client.this.id
    error_message = "Expected optional scopes to reference the client id."
  }
}

run "with_empty_scopes_object" {
  command = plan
  variables {
    scopes = {}
  }

  assert {
    condition     = length(keycloak_openid_client_default_scopes.this) == 0
    error_message = "Expected no default scopes resource when scopes object is empty."
  }

  assert {
    condition     = length(keycloak_openid_client_optional_scopes.this) == 0
    error_message = "Expected no optional scopes resource when scopes object is empty."
  }
}

run "without_scopes_variable" {
  command = plan

  assert {
    condition     = length(keycloak_openid_client_default_scopes.this) == 0
    error_message = "Expected no default scopes resource when scopes variable is not provided."
  }

  assert {
    condition     = length(keycloak_openid_client_optional_scopes.this) == 0
    error_message = "Expected no optional scopes resource when scopes variable is not provided."
  }
}
