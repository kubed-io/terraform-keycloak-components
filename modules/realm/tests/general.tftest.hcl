mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

# General tab + Themes + Login + Tokens flatten to top-level keycloak_realm args.

run "general_top_level" {
  command = plan
  variables {
    ssl_required                   = "external"
    user_managed_access            = true
    organizations_enabled          = true
    admin_permissions_enabled      = true
    internal_id                    = "fixed-internal-id"
    terraform_deletion_protection  = true
    attributes                     = { frontendUrl = "https://auth.example.com" }
    default_default_client_scopes  = ["profile", "email"]
    default_optional_client_scopes = ["address", "phone"]
  }

  assert {
    condition     = keycloak_realm.this.ssl_required == "external"
    error_message = "Expected ssl_required to be 'external'."
  }

  assert {
    condition     = keycloak_realm.this.user_managed_access == true
    error_message = "Expected user_managed_access to be true."
  }

  assert {
    condition     = keycloak_realm.this.admin_permissions_enabled == true
    error_message = "Expected admin_permissions_enabled to be true."
  }

  assert {
    condition     = keycloak_realm.this.internal_id == "fixed-internal-id"
    error_message = "Expected internal_id override to be applied."
  }

  assert {
    condition     = keycloak_realm.this.terraform_deletion_protection == true
    error_message = "Expected terraform_deletion_protection to be true."
  }

  assert {
    condition     = keycloak_realm.this.attributes["frontendUrl"] == "https://auth.example.com"
    error_message = "Expected the frontendUrl attribute to be set."
  }

  assert {
    condition     = length(keycloak_realm.this.default_default_client_scopes) == 2
    error_message = "Expected two default default client scopes."
  }
}

run "themes" {
  command = plan
  variables {
    themes = {
      loginTheme   = "keycloak"
      accountTheme = "keycloak.v3"
      adminTheme   = "keycloak.v2"
      emailTheme   = "keycloak"
    }
  }

  assert {
    condition     = keycloak_realm.this.login_theme == "keycloak"
    error_message = "Expected login_theme to be 'keycloak'."
  }

  assert {
    condition     = keycloak_realm.this.admin_theme == "keycloak.v2"
    error_message = "Expected admin_theme to be 'keycloak.v2'."
  }
}

run "login" {
  command = plan
  variables {
    login = {
      registrationAllowed   = true
      resetPasswordAllowed  = true
      rememberMe            = true
      verifyEmail           = true
      loginWithEmailAllowed = true
    }
  }

  assert {
    condition     = keycloak_realm.this.registration_allowed == true
    error_message = "Expected registration_allowed to be true."
  }

  assert {
    condition     = keycloak_realm.this.reset_password_allowed == true
    error_message = "Expected reset_password_allowed to be true."
  }

  assert {
    condition     = keycloak_realm.this.login_with_email_allowed == true
    error_message = "Expected login_with_email_allowed to be true."
  }
}

run "tokens" {
  command = plan
  variables {
    tokens = {
      ssoSessionIdleTimeout = "30m"
      ssoSessionMaxLifespan = "10h"
      accessTokenLifespan   = "5m"
      revokeRefreshToken    = true
      refreshTokenMaxReuse  = 0
    }
  }

  assert {
    condition     = keycloak_realm.this.sso_session_idle_timeout == "30m"
    error_message = "Expected sso_session_idle_timeout to be '30m'."
  }

  assert {
    condition     = keycloak_realm.this.access_token_lifespan == "5m"
    error_message = "Expected access_token_lifespan to be '5m'."
  }

  assert {
    condition     = keycloak_realm.this.revoke_refresh_token == true
    error_message = "Expected revoke_refresh_token to be true."
  }
}
