mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

run "none_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_realm_client_policy_profile.this) == 0
    error_message = "Expected no client profiles when unset."
  }

  assert {
    condition     = length(keycloak_realm_client_policy_profile_policy.this) == 0
    error_message = "Expected no client policies when unset."
  }
}

run "one_per_item" {
  command = plan
  variables {
    client_profiles = [
      {
        name        = "strong-client-auth"
        description = "Signed-JWT or mTLS client authentication only"
        executors = [
          {
            executor = "secure-client-authenticator"
            configuration = {
              allowed-client-authenticators = ["client-jwt", "client-x509"]
              default-client-authenticator  = "client-jwt"
            }
          },
          { executor = "secure-session" },
        ]
      },
      {
        name = "monthly-secret-rotation"
        executors = [
          {
            executor = "secret-rotation"
            configuration = {
              expiration-period         = 2592000
              rotated-expiration-period = 172800
              remaining-rotation-period = 864000
            }
          },
        ]
      },
    ]
    client_policies = [
      {
        name     = "confidential-clients"
        profiles = ["strong-client-auth", "monthly-secret-rotation"]
        conditions = [
          {
            condition = "client-access-type"
            configuration = {
              type              = ["confidential"]
              is-negative-logic = false
            }
          },
        ]
      },
      {
        name     = "banking-clients"
        enabled  = false
        profiles = ["fapi-1-advanced"]
        conditions = [
          {
            condition = "client-attributes"
            configuration = {
              attributes = [{ key = "segment", value = "banking" }]
            }
          },
        ]
      },
    ]
  }

  assert {
    condition     = keycloak_realm_client_policy_profile.this["strong-client-auth"].executor[0].name == "secure-client-authenticator"
    error_message = "Expected executor to map to the provider's executor name."
  }

  assert {
    condition     = keycloak_realm_client_policy_profile.this["strong-client-auth"].executor[0].configuration["allowed-client-authenticators"] == "[\"client-jwt\",\"client-x509\"]"
    error_message = "Expected a list to go over as compact JSON."
  }

  assert {
    condition     = keycloak_realm_client_policy_profile.this["strong-client-auth"].executor[0].configuration["default-client-authenticator"] == "client-jwt"
    error_message = "Expected a string to pass through untouched."
  }

  assert {
    condition     = length(keycloak_realm_client_policy_profile.this["strong-client-auth"].executor[1].configuration) == 0
    error_message = "Expected an executor without configuration to get an empty one."
  }

  assert {
    condition     = keycloak_realm_client_policy_profile.this["monthly-secret-rotation"].executor[0].configuration["expiration-period"] == "2592000"
    error_message = "Expected a number to go over as text."
  }

  assert {
    condition     = keycloak_realm_client_policy_profile_policy.this["confidential-clients"].condition[0].configuration["is-negative-logic"] == "false"
    error_message = "Expected a boolean to go over as text."
  }

  assert {
    condition     = keycloak_realm_client_policy_profile_policy.this["confidential-clients"].condition[0].configuration["type"] == "[\"confidential\"]"
    error_message = "Expected a condition list to go over as compact JSON."
  }

  assert {
    condition     = keycloak_realm_client_policy_profile_policy.this["confidential-clients"].enabled
    error_message = "Expected a policy to be enabled by default."
  }

  assert {
    condition     = keycloak_realm_client_policy_profile_policy.this["banking-clients"].condition[0].configuration["attributes"] == "[{\"key\":\"segment\",\"value\":\"banking\"}]"
    error_message = "Expected a list of maps to go over as compact JSON."
  }

  assert {
    condition     = !keycloak_realm_client_policy_profile_policy.this["banking-clients"].enabled
    error_message = "Expected enabled = false to pass through."
  }
}

run "rejects_duplicate_profile_names" {
  command = plan
  variables {
    client_profiles = [{ name = "x" }, { name = "x" }]
  }
  expect_failures = [var.client_profiles]
}

run "rejects_unknown_profile_key" {
  command = plan
  variables {
    client_profiles = [{ name = "x", executor = [] }]
  }
  expect_failures = [var.client_profiles]
}

run "rejects_executor_without_type" {
  command = plan
  variables {
    client_profiles = [{ name = "x", executors = [{ configuration = {} }] }]
  }
  expect_failures = [var.client_profiles]
}

run "rejects_policy_without_profiles" {
  command = plan
  variables {
    client_policies = [{ name = "x", profiles = [] }]
  }
  expect_failures = [var.client_policies]
}

run "rejects_unknown_policy_key" {
  command = plan
  variables {
    client_policies = [{ name = "x", profiles = ["y"], mode = "STRICT" }]
  }
  expect_failures = [var.client_policies]
}
