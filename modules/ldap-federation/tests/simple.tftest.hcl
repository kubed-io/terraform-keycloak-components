mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
}

run "simple_ldap_federation" {
  command = plan
  variables {
    name           = "tester"
    realm          = "my-realm"
    connection_url = "ldap://ldap.example.com:389"
    mappers = [{
      name = "users"
      type = "user"
      user = {
        baseDn        = "ou=users,dc=example,dc=com"
        objectClasses = ["inetOrgPerson", "organizationalPerson"]
      }
    }]
  }
}