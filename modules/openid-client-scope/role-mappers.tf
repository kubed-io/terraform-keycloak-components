locals {
  # realm roles keyed by name, client roles by "<client>/<name>"
  roles = {
    for r in var.roles :
    r.client == null ? r.name : "${r.client}/${r.name}" => r
  }
  role_clients = toset([
    for r in var.roles :
    r.client
    if r.client != null
  ])
}

# keycloak_role wants the client's internal ID, not its clientId
data "keycloak_openid_client" "role_client" {
  for_each  = local.role_clients
  realm_id  = data.keycloak_realm.this.id
  client_id = each.value
}

data "keycloak_role" "this" {
  for_each = local.roles
  realm_id = data.keycloak_realm.this.id
  client_id = (
    each.value.client == null
    ? null
    : data.keycloak_openid_client.role_client[each.value.client].id
  )
  name = each.value.name
}

resource "keycloak_generic_role_mapper" "this" {
  for_each = local.roles

  realm_id        = data.keycloak_realm.this.id
  client_scope_id = keycloak_openid_client_scope.this.id
  role_id         = data.keycloak_role.this[each.key].id
}
