mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

run "simple_realm" {
  command = plan

  assert {
    condition     = keycloak_realm.this.realm == "my-realm"
    error_message = "Expected realm to be 'my-realm'."
  }

  # enabled defaults to true
  assert {
    condition     = keycloak_realm.this.enabled == true
    error_message = "Expected realm to be enabled by default."
  }

  # display_name falls back to a title-cased realm name
  assert {
    condition     = keycloak_realm.this.display_name == "My-Realm"
    error_message = "Expected display_name to title-case the realm name."
  }

  # display_name_html falls back to the realm name
  assert {
    condition     = keycloak_realm.this.display_name_html == "my-realm"
    error_message = "Expected display_name_html to fall back to the realm name."
  }
}

run "explicit_display_names" {
  command = plan
  variables {
    display_name      = "My Realm"
    display_name_html = "<b>My Realm</b>"
    enabled           = false
  }

  assert {
    condition     = keycloak_realm.this.display_name == "My Realm"
    error_message = "Expected explicit display_name to be used."
  }

  assert {
    condition     = keycloak_realm.this.display_name_html == "<b>My Realm</b>"
    error_message = "Expected explicit display_name_html to be used."
  }

  assert {
    condition     = keycloak_realm.this.enabled == false
    error_message = "Expected realm to be disabled."
  }
}

# With no optional groups supplied, none of the nested blocks should be emitted.
run "no_nested_blocks_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_realm.this.smtp_server) == 0
    error_message = "Expected no smtp_server block when var.smtp is unset."
  }

  assert {
    condition     = length(keycloak_realm.this.internationalization) == 0
    error_message = "Expected no internationalization block when unset."
  }

  assert {
    condition     = length(keycloak_realm.this.security_defenses) == 0
    error_message = "Expected no security_defenses block when unset."
  }

  assert {
    condition     = length(keycloak_realm.this.otp_policy) == 0
    error_message = "Expected no otp_policy block when unset."
  }

  assert {
    condition     = length(keycloak_realm.this.web_authn_policy) == 0
    error_message = "Expected no web_authn_policy block when unset."
  }

  assert {
    condition     = length(keycloak_realm.this.web_authn_passwordless_policy) == 0
    error_message = "Expected no web_authn_passwordless_policy block when unset."
  }
}
