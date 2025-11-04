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
    id               = "test-client"
    realm            = "my-realm"
    access_type      = "INVALID"
  }
  expect_failures = [var.access_type]
}
