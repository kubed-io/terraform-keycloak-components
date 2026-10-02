resource "keycloak_realm_client_registration_policy" "this" {
  for_each    = { for p in var.client_registration : "${p.subType}/${p.name}" => p }
  realm_id    = keycloak_realm.this.id
  name        = each.value.name
  provider_id = each.value.providerId
  sub_type    = each.value.subType
  config      = each.value.config
}
