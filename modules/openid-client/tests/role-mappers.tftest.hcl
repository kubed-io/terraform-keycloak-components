mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
}
mock_provider "http" {}

variables {
  realm       = "my-realm"
  id          = "myapp"
  access_type = "CONFIDENTIAL"
  creds = {
    url      = "http://kc:8080"
    username = "admin"
    password = "pw"
  }
}

# An ldap-type mapper resolves the federation GUID by name from the components endpoint
# and wires it onto the keycloak_ldap_role_mapper as a CLIENT-role mapper for this client.
run "ldap_mapper_resolves_guid_and_is_client_scoped" {
  command = plan
  variables {
    role_mappers = [{
      name = "app client roles"
      type = "ldap"
      ldap = {
        baseDn = "cn=myapp,ou=clients,dc=example"
        # federationId omitted → defaults to the realm name "my-realm"
      }
    }]
  }

  override_data {
    target = data.http.token
    values = { response_body = "{\"access_token\":\"tok-123\"}" }
  }
  override_data {
    target = data.http.federation
    values = { response_body = "[{\"id\":\"FED-GUID-1\",\"name\":\"my-realm\"}]" }
  }

  assert {
    condition     = keycloak_ldap_role_mapper.this["app client roles"].ldap_user_federation_id == "FED-GUID-1"
    error_message = "federation GUID should come from the resolved components response"
  }
  assert {
    condition     = keycloak_ldap_role_mapper.this["app client roles"].use_realm_roles_mapping == false
    error_message = "a client-bound ldap role mapper must have use_realm_roles_mapping = false"
  }
  assert {
    condition     = keycloak_ldap_role_mapper.this["app client roles"].ldap_roles_dn == "cn=myapp,ou=clients,dc=example"
    error_message = "baseDn should map to ldap_roles_dn"
  }
  # one token call + one federation lookup
  assert {
    condition     = length(data.http.token) == 1
    error_message = "exactly one admin-token call expected when an ldap mapper exists"
  }
  assert {
    condition     = length(data.http.federation) == 1
    error_message = "one federation lookup for the single referenced federation name"
  }
}

# Two ldap mappers sharing a federation name → the lookup is deduped to ONE http call.
run "federation_lookup_deduped_by_name" {
  command = plan
  variables {
    role_mappers = [
      {
        name = "app roles"
        type = "ldap"
        ldap = { baseDn = "cn=myapp,ou=clients,dc=example", federationId = "shared-fed" }
      },
      {
        name = "other roles"
        type = "ldap"
        ldap = { baseDn = "cn=other,ou=clients,dc=example", federationId = "shared-fed" }
      },
    ]
  }
  override_data {
    target = data.http.token
    values = { response_body = "{\"access_token\":\"tok-123\"}" }
  }
  override_data {
    target = data.http.federation
    values = { response_body = "[{\"id\":\"FED-GUID-1\"}]" }
  }

  assert {
    condition     = length(data.http.federation) == 1
    error_message = "two mappers on the same federation name must dedupe to one lookup"
  }
  assert {
    condition     = length(keycloak_ldap_role_mapper.this) == 2
    error_message = "still two distinct role mappers"
  }
}

# No ldap mappers → all http/creds machinery is inert (no token call, no lookups).
run "no_ldap_is_inert" {
  command = plan
  variables {
    role_mappers = []
  }

  assert {
    condition     = length(data.http.token) == 0
    error_message = "no token call when there are no ldap mappers"
  }
  assert {
    condition     = length(data.http.federation) == 0
    error_message = "no federation lookups when there are no ldap mappers"
  }
  assert {
    condition     = length(keycloak_ldap_role_mapper.this) == 0
    error_message = "no ldap role mappers"
  }
}

# Generic mappers need no http/creds at all.
run "generic_mapper_no_http" {
  command = plan
  variables {
    role_mappers = [{
      name    = "scope my role"
      type    = "generic"
      generic = { roleId = "some-role-uuid" }
    }]
  }

  assert {
    condition     = length(data.http.token) == 0
    error_message = "generic-only mappers must not trigger the token call"
  }
  assert {
    condition     = keycloak_generic_role_mapper.this["scope my role"].role_id == "some-role-uuid"
    error_message = "generic mapper should pass through roleId"
  }
}
