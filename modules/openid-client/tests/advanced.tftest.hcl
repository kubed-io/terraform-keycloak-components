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

run "full_scope_allowed" {
  command = plan
  variables {
    full_scope_allowed = false
  }

  assert {
    condition     = keycloak_openid_client.this.full_scope_allowed == false
    error_message = "Expected full_scope_allowed to be false."
  }
}

run "tokens" {
  command = plan
  variables {
    tokens = {
      accessTokenLifespan      = "300"
      clientSessionIdleTimeout = "1800"
      requireDpopBoundTokens   = true
    }
  }

  assert {
    condition     = keycloak_openid_client.this.access_token_lifespan == "300"
    error_message = "Expected access_token_lifespan to be 300."
  }

  assert {
    condition     = keycloak_openid_client.this.client_session_idle_timeout == "1800"
    error_message = "Expected client_session_idle_timeout to be 1800."
  }

  assert {
    condition     = keycloak_openid_client.this.require_dpop_bound_tokens == true
    error_message = "Expected require_dpop_bound_tokens to be true."
  }
}

run "compatibility" {
  command = plan
  variables {
    compatibility = {
      excludeIssuerFromAuthResponse            = true
      useRefreshTokens                         = false
      allowRefreshTokenInStandardTokenExchange = "SAME_SESSION"
    }
  }

  assert {
    condition     = keycloak_openid_client.this.exclude_issuer_from_auth_response == true
    error_message = "Expected exclude_issuer_from_auth_response to be true."
  }

  assert {
    condition     = keycloak_openid_client.this.use_refresh_tokens == false
    error_message = "Expected use_refresh_tokens to be false."
  }

  assert {
    condition     = keycloak_openid_client.this.allow_refresh_token_in_standard_token_exchange == "SAME_SESSION"
    error_message = "Expected allow_refresh_token_in_standard_token_exchange to be SAME_SESSION."
  }
}

run "rejects_bad_refresh_token_mode" {
  command = plan
  variables {
    compatibility = {
      allowRefreshTokenInStandardTokenExchange = "ALWAYS"
    }
  }
  expect_failures = [var.compatibility]
}
