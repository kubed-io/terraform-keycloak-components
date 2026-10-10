# One profile per realm; the provider replaces it whole.
resource "keycloak_realm_user_profile" "this" {
  count = var.user_profile == null ? 0 : 1

  realm_id                   = keycloak_realm.this.id
  unmanaged_attribute_policy = var.user_profile.unmanagedAttributePolicy

  dynamic "attribute" {
    for_each = var.user_profile.attributes
    content {
      name                = attribute.value.name
      display_name        = attribute.value.displayName
      group               = attribute.value.group
      default_value       = attribute.value.defaultValue
      multi_valued        = attribute.value.multiValued
      enabled_when_scope  = attribute.value.enabledWhenScope
      required_for_roles  = attribute.value.requiredForRoles
      required_for_scopes = attribute.value.requiredForScopes
      annotations         = attribute.value.annotations

      dynamic "permissions" {
        for_each = (
          attribute.value.permissions == null
          ? []
          : [attribute.value.permissions]
        )
        content {
          view = permissions.value.view
          edit = permissions.value.edit
        }
      }

      dynamic "validator" {
        for_each = attribute.value.validators
        content {
          name   = validator.key
          config = validator.value
        }
      }
    }
  }

  dynamic "group" {
    for_each = var.user_profile.groups
    content {
      name                = group.value.name
      display_header      = group.value.displayHeader
      display_description = group.value.displayDescription
      annotations         = group.value.annotations
    }
  }
}
