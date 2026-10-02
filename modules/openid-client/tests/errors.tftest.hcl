mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
}

# run "realm_required" {
#   command = plan
#   variables {
#     id               = "test-client"
#     access_type      = "CONFIDENTIAL"
#   }
#   expect_failures = [var.realm]
# }

run "invalid_access_type" {
  command = plan
  variables {
    id          = "test-client"
    realm       = "my-realm"
    access_type = "INVALID"
  }
  expect_failures = [var.access_type]
}

run "invalid_pkce_method" {
  command = plan
  variables {
    id           = "test-client"
    realm        = "my-realm"
    access_type  = "CONFIDENTIAL"
    capabilities = { pkceCodeChallengeMethod = "S512" }
  }
  expect_failures = [var.capabilities]
}

run "invalid_policy_enforcement_mode" {
  command = plan
  variables {
    id            = "test-client"
    realm         = "my-realm"
    access_type   = "CONFIDENTIAL"
    authorization = { policyEnforcementMode = "STRICT" }
  }
  expect_failures = [var.authorization]
}

run "invalid_permission_scope" {
  command = plan
  variables {
    id          = "test-client"
    realm       = "my-realm"
    access_type = "CONFIDENTIAL"
    permissions = [{ scope = "delete" }]
  }
  expect_failures = [var.permissions]
}
