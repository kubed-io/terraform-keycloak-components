resource "keycloak_openid_client_optional_scopes" "this" {
  count           = var.scopes.optional == null ? 0 : 1
  realm_id        = data.keycloak_realm.this.id
  client_id       = keycloak_openid_client.this.id
  optional_scopes = var.scopes.optional
}

resource "keycloak_openid_client_default_scopes" "this" {
  count          = var.scopes.default == null ? 0 : 1
  realm_id       = data.keycloak_realm.this.id
  client_id      = keycloak_openid_client.this.id
  default_scopes = var.scopes.default
}
