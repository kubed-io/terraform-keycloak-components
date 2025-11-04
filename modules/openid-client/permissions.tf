resource "keycloak_openid_client_permissions" "this" {
  count     = var.permissions == null ? 0 : 1
  realm_id  = data.keycloak_realm.this.id
  client_id = keycloak_openid_client.this.id

  dynamic "view_scope" {
    for_each = [
      for p in var.permissions : p 
      if p.scope == "view"
    ]
    content {
      policies          = view_scope.value.policies
      description       = view_scope.value.description
      decision_strategy = view_scope.value.decisionStrategy
    }
  }

  dynamic "manage_scope" {
    for_each = [
      for p in var.permissions : p 
      if p.scope == "manage"
    ]
    content {
      policies          = manage_scope.value.policies
      description       = manage_scope.value.description
      decision_strategy = manage_scope.value.decisionStrategy
    }
  }

  dynamic "configure_scope" {
    for_each = [
      for p in var.permissions : p 
      if p.scope == "configure"
    ]
    content {
      policies          = configure_scope.value.policies
      description       = configure_scope.value.description
      decision_strategy = configure_scope.value.decisionStrategy
    }
  }

  dynamic "map_roles_scope" {
    for_each = [
      for p in var.permissions : p 
      if p.scope == "map-roles"
    ]
    content {
      policies          = map_roles_scope.value.policies
      description       = map_roles_scope.value.description
      decision_strategy = map_roles_scope.value.decisionStrategy
    }
  }

  dynamic "map_roles_client_scope_scope" {
    for_each = [
      for p in var.permissions : p 
      if p.scope == "map-roles-client-scope"
    ]
    content {
      policies          = map_roles_client_scope_scope.value.policies
      description       = map_roles_client_scope_scope.value.description
      decision_strategy = map_roles_client_scope_scope.value.decisionStrategy
    }
  }

  dynamic "map_roles_composite_scope" {
    for_each = [
      for p in var.permissions : p 
      if p.scope == "map-roles-composite"
    ]
    content {
      policies          = map_roles_composite_scope.value.policies
      description       = map_roles_composite_scope.value.description
      decision_strategy = map_roles_composite_scope.value.decisionStrategy
    }
  }

  dynamic "token_exchange_scope" {
    for_each = [
      for p in var.permissions : p 
      if p.scope == "token-exchange"
    ]
    content {
      policies          = token_exchange_scope.value.policies
      description       = token_exchange_scope.value.description
      decision_strategy = token_exchange_scope.value.decisionStrategy
    }
  }
}
