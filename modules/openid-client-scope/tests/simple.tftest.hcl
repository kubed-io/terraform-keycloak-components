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

run "simple_scope" {
  command = plan

  assert {
    condition     = keycloak_openid_client_scope.this.name == "mcp"
    error_message = "Expected the scope name to be 'mcp'."
  }

  assert {
    condition     = keycloak_openid_client_scope.this.realm_id == "example-realm-id"
    error_message = "Expected the scope to be created in the looked-up realm."
  }
}

run "settings" {
  command = plan
  variables {
    description                         = "MCP access"
    consent_screen_text                 = "Use your MCP tools"
    include_in_token_scope              = false
    include_in_openid_provider_metadata = false
    gui_order                           = 3
    extra_config                        = { custom = "value" }
  }

  assert {
    condition     = keycloak_openid_client_scope.this.consent_screen_text == "Use your MCP tools"
    error_message = "Expected consent_screen_text to pass through."
  }

  assert {
    condition     = keycloak_openid_client_scope.this.include_in_token_scope == false
    error_message = "Expected include_in_token_scope to be false."
  }

  assert {
    condition     = keycloak_openid_client_scope.this.include_in_openid_provider_metadata == false
    error_message = "Expected include_in_openid_provider_metadata to be false."
  }

  assert {
    condition     = keycloak_openid_client_scope.this.gui_order == 3
    error_message = "Expected gui_order to be 3."
  }

  assert {
    condition     = keycloak_openid_client_scope.this.extra_config["custom"] == "value"
    error_message = "Expected extra_config to pass through."
  }
}
