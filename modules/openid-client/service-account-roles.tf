locals {
  # realm roles keyed by name, client roles by "<client>/<name>"
  sa_roles = {
    for r in var.service_account_roles :
    r.client == null ? r.name : "${r.client}/${r.name}" => r
  }
  sa_realm_roles = {
    for k, r in local.sa_roles :
    k => r
    if r.client == null
  }
  sa_client_roles = {
    for k, r in local.sa_roles :
    k => r
    if r.client != null
  }
  # this client is not looked up: it does not exist yet on the first plan
  sa_role_clients = toset([
    for r in var.service_account_roles :
    r.client
    if r.client != null && r.client != local.id
  ])
}

data "keycloak_openid_client" "sa_role_client" {
  for_each  = local.sa_role_clients
  realm_id  = data.keycloak_realm.this.id
  client_id = each.value
}

resource "keycloak_openid_client_service_account_realm_role" "this" {
  for_each                = local.sa_realm_roles
  realm_id                = data.keycloak_realm.this.id
  service_account_user_id = keycloak_openid_client.this.service_account_user_id
  role                    = each.value.name
}

resource "keycloak_openid_client_service_account_role" "this" {
  for_each                = local.sa_client_roles
  realm_id                = data.keycloak_realm.this.id
  service_account_user_id = keycloak_openid_client.this.service_account_user_id
  client_id = (
    each.value.client == local.id
    ? keycloak_openid_client.this.id
    : data.keycloak_openid_client.sa_role_client[each.value.client].id
  )
  role = each.value.name
}
