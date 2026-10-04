# Keycloak keeps one profile list and one policy list per realm and only accepts each list
# whole, so every resource below reads the list, edits its entry and writes it all back.
# Two of those running at once lose a write, and the provider never notices the entry is
# gone; the Realm composition applies with -parallelism=1 for that reason.

locals {
  # The provider takes configuration as a string map and parses a value starting with
  # [ or { as JSON, so lists and maps go over as JSON and plain values as text.
  client_profiles = {
    for p in var.client_profiles :
    p.name => {
      description = try(p.description, null)
      executors = [
        for e in try(p.executors, []) :
        {
          executor = e.executor
          configuration = try({
            for k, v in e.configuration :
            k => (
              can(tostring(v))
              ? tostring(v)
              : jsonencode(v)
            )
            if v != null
          }, {})
        }
      ]
    }
  }

  client_policies = {
    for p in var.client_policies :
    p.name => {
      description = try(p.description, null)
      enabled     = try(p.enabled, true)
      profiles    = p.profiles
      conditions = [
        for c in try(p.conditions, []) :
        {
          condition = c.condition
          configuration = try({
            for k, v in c.configuration :
            k => (
              can(tostring(v))
              ? tostring(v)
              : jsonencode(v)
            )
            if v != null
          }, {})
        }
      ]
    }
  }
}

resource "keycloak_realm_client_policy_profile" "this" {
  for_each    = local.client_profiles
  realm_id    = keycloak_realm.this.id
  name        = each.key
  description = each.value.description

  dynamic "executor" {
    for_each = each.value.executors
    content {
      name          = executor.value.executor
      configuration = executor.value.configuration
    }
  }
}

resource "keycloak_realm_client_policy_profile_policy" "this" {
  for_each    = local.client_policies
  realm_id    = keycloak_realm.this.id
  name        = each.key
  description = each.value.description
  enabled     = each.value.enabled
  profiles    = each.value.profiles

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      name          = condition.value.condition
      configuration = condition.value.configuration
    }
  }

  # Keycloak rejects a policy naming a profile it does not have yet.
  depends_on = [keycloak_realm_client_policy_profile.this]
}
