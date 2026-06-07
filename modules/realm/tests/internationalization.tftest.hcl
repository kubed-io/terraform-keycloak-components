mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

run "no_block_when_unset" {
  command = plan

  assert {
    condition     = length(keycloak_realm.this.internationalization) == 0
    error_message = "Expected no internationalization block when unset."
  }
}

run "supported_locales" {
  command = plan
  variables {
    internationalization = {
      supportedLocales = ["en", "de", "es"]
      defaultLocale    = "en"
    }
  }

  assert {
    condition     = length(keycloak_realm.this.internationalization) == 1
    error_message = "Expected one internationalization block."
  }

  assert {
    condition     = keycloak_realm.this.internationalization[0].default_locale == "en"
    error_message = "Expected default_locale to be 'en'."
  }

  assert {
    condition     = length(keycloak_realm.this.internationalization[0].supported_locales) == 3
    error_message = "Expected three supported locales."
  }
}
