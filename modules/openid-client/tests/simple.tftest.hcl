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

run "simple_openid_client" {
  command = plan

  # Verify the client is created
  assert {
    condition     = keycloak_openid_client.this.realm_id == "example-realm-id"
    error_message = "Expected realm_id to be 'example-realm-id'."
  }

  assert {
    condition     = keycloak_openid_client.this.enabled == true
    error_message = "Expected client to be enabled by default."
  }
}

run "client_with_custom_id" {
  command = plan
  variables {
    id               = "custom-client-id"
    name             = "Custom Client Name"
  }

  assert {
    condition     = keycloak_openid_client.this.client_id == "custom-client-id"
    error_message = "Expected client_id to be 'custom-client-id'."
  }

  assert {
    condition     = keycloak_openid_client.this.name == "Custom Client Name"
    error_message = "Expected client name to be 'Custom Client Name'."
  }
}

run "client_with_access_settings" {
  command = plan
  variables {
    access_settings = {
      rootUrl      = "https://example.com"
      redirectUris = ["https://example.com/callback"]
      webOrigins   = ["https://example.com"]
    }
  }

  assert {
    condition     = keycloak_openid_client.this.root_url == "https://example.com"
    error_message = "Expected root_url to be 'https://example.com'."
  }

  assert {
    condition     = length(keycloak_openid_client.this.valid_redirect_uris) == 1
    error_message = "Expected one redirect URI."
  }
}

run "client_with_capabilities" {
  command = plan
  variables {
    capabilities = {
      standardFlowEnabled       = true
      directAccessGrantsEnabled = true
      serviceAccountsEnabled    = true
      pkceCodeChallengeMethod   = "S256"
    }
  }

  assert {
    condition     = keycloak_openid_client.this.standard_flow_enabled == true
    error_message = "Expected standard_flow_enabled to be true."
  }

  assert {
    condition     = keycloak_openid_client.this.service_accounts_enabled == true
    error_message = "Expected service_accounts_enabled to be true."
  }

  assert {
    condition     = keycloak_openid_client.this.pkce_code_challenge_method == "S256"
    error_message = "Expected pkce_code_challenge_method to be 'S256'."
  }
}
