mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

run "none_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_required_action.this) == 0
    error_message = "Expected no required actions when required_actions is null."
  }
}

run "update_email_forces_verification" {
  command = plan
  variables {
    required_actions = {
      UPDATE_EMAIL = {
        config = {
          verifyEmail = "true"
        }
      }
    }
  }

  assert {
    condition     = keycloak_required_action.this["UPDATE_EMAIL"].alias == "UPDATE_EMAIL"
    error_message = "Expected the map key to be the alias."
  }

  assert {
    condition     = keycloak_required_action.this["UPDATE_EMAIL"].realm_id == keycloak_realm.this.id
    error_message = "Expected the action on this realm."
  }

  assert {
    condition     = keycloak_required_action.this["UPDATE_EMAIL"].enabled == true
    error_message = "Expected enabled to default to true."
  }

  assert {
    condition     = keycloak_required_action.this["UPDATE_EMAIL"].config["verifyEmail"] == "true"
    error_message = "Expected the config to pass through."
  }
}

run "all_settings" {
  command = plan
  variables {
    required_actions = {
      CONFIGURE_TOTP = {
        enabled       = true
        defaultAction = true
        priority      = 10
        name          = "Set up an authenticator"
      }
      TERMS_AND_CONDITIONS = {
        enabled = false
      }
    }
  }

  assert {
    condition     = keycloak_required_action.this["CONFIGURE_TOTP"].default_action == true
    error_message = "Expected defaultAction to pass through."
  }

  assert {
    condition     = keycloak_required_action.this["CONFIGURE_TOTP"].priority == 10
    error_message = "Expected the priority."
  }

  assert {
    condition     = keycloak_required_action.this["CONFIGURE_TOTP"].name == "Set up an authenticator"
    error_message = "Expected the display name."
  }

  assert {
    condition     = keycloak_required_action.this["TERMS_AND_CONDITIONS"].enabled == false
    error_message = "Expected an action to be disabled."
  }
}
