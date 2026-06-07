mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

# Authentication → Policies: password_policy is a flat arg; otp_policy / web_authn_policy /
# web_authn_passwordless_policy are each independently-gated single nested blocks.

run "password_policy" {
  command = plan
  variables {
    policies = {
      passwordPolicy = "upperCase(1) and length(8) and notUsername"
    }
  }

  assert {
    condition     = keycloak_realm.this.password_policy == "upperCase(1) and length(8) and notUsername"
    error_message = "Expected the password policy to be set."
  }

  # No nested policy objects supplied → no nested blocks.
  assert {
    condition     = length(keycloak_realm.this.otp_policy) == 0
    error_message = "Expected no otp_policy block when only passwordPolicy is set."
  }
}

run "otp_policy" {
  command = plan
  variables {
    policies = {
      otpPolicy = {
        type         = "totp"
        algorithm    = "HmacSHA1"
        digits       = 6
        period       = 30
        codeReusable = false
      }
    }
  }

  assert {
    condition     = length(keycloak_realm.this.otp_policy) == 1
    error_message = "Expected one otp_policy block."
  }

  assert {
    condition     = keycloak_realm.this.otp_policy[0].type == "totp"
    error_message = "Expected otp type to be 'totp'."
  }

  assert {
    condition     = keycloak_realm.this.otp_policy[0].digits == 6
    error_message = "Expected otp digits to be 6."
  }

  assert {
    condition     = keycloak_realm.this.otp_policy[0].code_reusable == false
    error_message = "Expected otp code_reusable to be false."
  }
}

run "web_authn_policy" {
  command = plan
  variables {
    policies = {
      webAuthnPolicy = {
        relyingPartyEntityName = "Example"
        relyingPartyId         = "auth.example.com"
        signatureAlgorithms    = ["ES256", "RS256"]
      }
    }
  }

  assert {
    condition     = length(keycloak_realm.this.web_authn_policy) == 1
    error_message = "Expected one web_authn_policy block."
  }

  assert {
    condition     = keycloak_realm.this.web_authn_policy[0].relying_party_entity_name == "Example"
    error_message = "Expected the relying party entity name to be 'Example'."
  }

  assert {
    condition     = length(keycloak_realm.this.web_authn_policy[0].signature_algorithms) == 2
    error_message = "Expected two signature algorithms."
  }
}

run "web_authn_passwordless_policy" {
  command = plan
  variables {
    policies = {
      webAuthnPasswordlessPolicy = {
        relyingPartyEntityName      = "Example Passwordless"
        passwordlessPasskeysEnabled = true
      }
    }
  }

  assert {
    condition     = length(keycloak_realm.this.web_authn_passwordless_policy) == 1
    error_message = "Expected one web_authn_passwordless_policy block."
  }

  assert {
    condition     = keycloak_realm.this.web_authn_passwordless_policy[0].passwordless_passkeys_enabled == true
    error_message = "Expected passwordless_passkeys_enabled to be true."
  }
}

run "all_three_policy_blocks" {
  command = plan
  variables {
    policies = {
      passwordPolicy             = "length(12)"
      otpPolicy                  = { type = "hotp" }
      webAuthnPolicy             = { relyingPartyId = "auth.example.com" }
      webAuthnPasswordlessPolicy = { relyingPartyId = "auth.example.com" }
    }
  }

  assert {
    condition     = length(keycloak_realm.this.otp_policy) == 1 && length(keycloak_realm.this.web_authn_policy) == 1 && length(keycloak_realm.this.web_authn_passwordless_policy) == 1
    error_message = "Expected all three nested policy blocks to be emitted."
  }
}
