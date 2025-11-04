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

run "with_role_mapper" {
  command = plan
  variables {
    mappers = [{
      type = "user"
      user = {
        baseDn        = "ou=users,dc=example,dc=com"
        objectClasses = ["inetOrgPerson", "organizationalPerson"]
      }
      }, {
      name = "To example role"
      type = "hardcodedRole"
      hardcodedRole = {
        name = "example-role"
      }
    }]
  }
  # verify there is one keycloak_ldap_hardcoded_role_mapper
  assert {
    condition     = length(keycloak_ldap_hardcoded_role_mapper.this) == 1
    error_message = "Expected exactly one keycloak_ldap_hardcoded_role_mapper to be created."
  }
}
