mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

run "none_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_realm_client_registration_policy.this) == 0
    error_message = "Expected no client registration policies when unset."
  }
}

run "one_per_item" {
  command = plan
  variables {
    client_registration = [
      {
        name       = "MCP Trusted Hosts"
        providerId = "trusted-hosts"
        subType    = "anonymous"
        config = {
          "trusted-hosts"          = "localhost,127.0.0.1"
          "client-uris-must-match" = "true"
        }
      },
      {
        name       = "MCP Trusted Hosts"
        providerId = "trusted-hosts"
        subType    = "authenticated"
      },
    ]
  }

  assert {
    condition     = length(keycloak_realm_client_registration_policy.this) == 2
    error_message = "Expected one policy per item; the same name is allowed across subTypes."
  }

  assert {
    condition     = keycloak_realm_client_registration_policy.this["anonymous/MCP Trusted Hosts"].config["trusted-hosts"] == "localhost,127.0.0.1"
    error_message = "Expected the config map to pass through."
  }

  assert {
    condition     = keycloak_realm_client_registration_policy.this["authenticated/MCP Trusted Hosts"].provider_id == "trusted-hosts"
    error_message = "Expected providerId to map to provider_id."
  }
}

run "rejects_unknown_sub_type" {
  command = plan
  variables {
    client_registration = [{ name = "x", providerId = "max-clients", subType = "public" }]
  }
  expect_failures = [var.client_registration]
}

run "rejects_duplicate_name_in_sub_type" {
  command = plan
  variables {
    client_registration = [
      { name = "x", providerId = "max-clients", subType = "anonymous" },
      { name = "x", providerId = "trusted-hosts", subType = "anonymous" },
    ]
  }
  expect_failures = [var.client_registration]
}
