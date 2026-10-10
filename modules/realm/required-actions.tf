resource "keycloak_required_action" "this" {
  for_each = coalesce(var.required_actions, {})

  realm_id       = keycloak_realm.this.id
  alias          = each.key
  enabled        = each.value.enabled
  default_action = each.value.defaultAction
  priority       = each.value.priority
  name           = each.value.name
  config         = each.value.config
}
