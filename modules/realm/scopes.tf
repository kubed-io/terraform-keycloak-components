resource "keycloak_realm_default_client_scopes" "this" {
  count          = var.client_scopes.default == null ? 0 : 1
  realm_id       = keycloak_realm.this.id
  default_scopes = var.client_scopes.default
}

resource "keycloak_realm_optional_client_scopes" "this" {
  count           = var.client_scopes.optional == null ? 0 : 1
  realm_id        = keycloak_realm.this.id
  optional_scopes = var.client_scopes.optional
}
