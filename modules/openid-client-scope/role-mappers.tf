resource "keycloak_generic_role_mapper" "this" {
  for_each = { for m in var.role_mappers : m.roleId => m }

  realm_id        = data.keycloak_realm.this.id
  client_scope_id = keycloak_openid_client_scope.this.id
  role_id         = each.value.roleId
}
