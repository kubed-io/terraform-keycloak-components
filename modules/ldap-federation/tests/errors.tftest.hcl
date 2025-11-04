mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
}

variables {
  name           = "tester"
  realm          = "my-realm"
  connection_url = "ldap://ldap.example.com:389"
}

run "user_mapper_required" {
  command         = plan
  expect_failures = [var.mappers]
}

run "mapper_type_mismatch" {
  command = plan
  variables {
    mappers = [{
      type = "user"
      hardcodedRole = {
        name = "example-role"
      }
    }]
  }
  expect_failures = [var.mappers]
}
