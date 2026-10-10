# Authorization services: this client as a resource server, with its scopes, resources,
# policies and permissions. Everything refers to everything else by name; the names are
# resolved to Keycloak IDs here.

locals {
  authz_policy_list = var.authorization == null ? [] : var.authorization.policies
  authz_scopes      = { for s in try(var.authorization.scopes, []) : s.name => s }
  authz_resources   = { for r in try(var.authorization.resources, []) : r.name => r }
  authz_policies    = { for p in local.authz_policy_list : p.name => p }
  authz_permissions = { for p in try(var.authorization.permissions, []) : p.name => p }

  # --- names to look up -----------------------------------------------------------------
  # roles keyed like service_account_roles: realm roles by name, client roles by "<client>/<name>"
  authz_roles = merge({}, [
    for p in local.authz_policy_list : {
      for r in p.role.roles :
      r.client == null ? r.name : "${r.client}/${r.name}" => r
    }
    if p.type == "role"
  ]...)
  authz_users = toset(flatten([
    for p in local.authz_policy_list :
    p.user.users
    if p.type == "user"
  ]))
  authz_group_paths = toset(flatten([
    for p in local.authz_policy_list :
    p.group.groups[*].path
    if p.type == "group"
  ]))
  authz_client_scopes = toset(flatten([
    for p in local.authz_policy_list :
    p.clientScope.scopes[*].name
    if p.type == "clientScope"
  ]))
  # other clients, for client roles and client policies; this client is not looked up
  # because it does not exist yet on the first plan
  authz_clients = setsubtract(toset(concat(
    compact([for r in values(local.authz_roles) : r.client]),
    flatten([
      for p in local.authz_policy_list :
      p.client.clients
      if p.type == "client"
    ]),
  )), [local.id])

  # --- policy IDs by name, for aggregates (plain policies) and permissions (all) -----------
  authz_plain_policy_ids = merge(
    { for k, p in keycloak_openid_client_role_policy.this : k => p.id },
    { for k, p in keycloak_openid_client_group_policy.this : k => p.id },
    { for k, p in keycloak_openid_client_user_policy.this : k => p.id },
    { for k, p in keycloak_openid_client_client_policy.this : k => p.id },
    { for k, p in keycloak_openid_client_authorization_client_scope_policy.this : k => p.id },
    { for k, p in keycloak_openid_client_time_policy.this : k => p.id },
    { for k, p in keycloak_openid_client_regex_policy.this : k => p.id },
  )
  authz_policy_ids = merge(
    local.authz_plain_policy_ids,
    { for k, p in keycloak_openid_client_aggregate_policy.this : k => p.id },
  )
}

# --- lookups ------------------------------------------------------------------------------

data "keycloak_openid_client" "authz" {
  for_each  = local.authz_clients
  realm_id  = data.keycloak_realm.this.id
  client_id = each.value
}

data "keycloak_role" "authz" {
  for_each = local.authz_roles
  realm_id = data.keycloak_realm.this.id
  client_id = (
    each.value.client == null
    ? null
    : (
      each.value.client == local.id
      ? keycloak_openid_client.this.id
      : data.keycloak_openid_client.authz[each.value.client].id
    )
  )
  name = each.value.name

  # this client's own roles come from its LDAP role mappers; look up after they are synced
  depends_on = [data.http.role_sync]
}

data "keycloak_user" "authz" {
  for_each = local.authz_users
  realm_id = data.keycloak_realm.this.id
  username = each.value
}

data "keycloak_group" "authz" {
  for_each   = local.authz_group_paths
  realm_id   = data.keycloak_realm.this.id
  group_path = each.value
}

data "keycloak_openid_client_scope" "authz" {
  for_each = local.authz_client_scopes
  realm_id = data.keycloak_realm.this.id
  name     = each.value
}

# --- scopes and resources -----------------------------------------------------------------

resource "keycloak_openid_client_authorization_scope" "this" {
  for_each           = local.authz_scopes
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  display_name       = each.value.displayName
  icon_uri           = each.value.iconUri
}

resource "keycloak_openid_client_authorization_resource" "this" {
  for_each             = local.authz_resources
  realm_id             = data.keycloak_realm.this.id
  resource_server_id   = keycloak_openid_client.this.resource_server_id
  name                 = each.key
  display_name         = each.value.displayName
  type                 = each.value.type
  uris                 = each.value.uris
  icon_uri             = each.value.iconUri
  owner_managed_access = each.value.ownerManagedAccess
  attributes           = each.value.attributes
  # by name, through the scope resources so they are created first
  scopes = [
    for s in each.value.scopes :
    keycloak_openid_client_authorization_scope.this[s].name
  ]
}

# --- policies, one resource per type ------------------------------------------------------

resource "keycloak_openid_client_role_policy" "this" {
  for_each = {
    for k, p in local.authz_policies :
    k => p
    if p.type == "role"
  }
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  type               = "role"
  description        = each.value.description
  logic              = each.value.logic
  decision_strategy  = each.value.decisionStrategy
  fetch_roles        = each.value.role.fetchRoles

  dynamic "role" {
    for_each = each.value.role.roles
    content {
      id       = data.keycloak_role.authz[role.value.client == null ? role.value.name : "${role.value.client}/${role.value.name}"].id
      required = role.value.required
    }
  }
}

resource "keycloak_openid_client_group_policy" "this" {
  for_each = {
    for k, p in local.authz_policies :
    k => p
    if p.type == "group"
  }
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  description        = each.value.description
  logic              = each.value.logic
  decision_strategy  = each.value.decisionStrategy
  groups_claim       = each.value.group.groupsClaim

  dynamic "groups" {
    for_each = each.value.group.groups
    content {
      id              = data.keycloak_group.authz[groups.value.path].id
      path            = groups.value.path
      extend_children = groups.value.extendChildren
    }
  }
}

resource "keycloak_openid_client_user_policy" "this" {
  for_each = {
    for k, p in local.authz_policies :
    k => p
    if p.type == "user"
  }
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  description        = each.value.description
  logic              = each.value.logic
  decision_strategy  = each.value.decisionStrategy
  users = [
    for u in each.value.user.users :
    data.keycloak_user.authz[u].id
  ]
}

resource "keycloak_openid_client_client_policy" "this" {
  for_each = {
    for k, p in local.authz_policies :
    k => p
    if p.type == "client"
  }
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  description        = each.value.description
  logic              = each.value.logic
  decision_strategy  = each.value.decisionStrategy
  clients = [
    for c in each.value.client.clients :
    c == local.id ? keycloak_openid_client.this.id : data.keycloak_openid_client.authz[c].id
  ]
}

resource "keycloak_openid_client_authorization_client_scope_policy" "this" {
  for_each = {
    for k, p in local.authz_policies :
    k => p
    if p.type == "clientScope"
  }
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  description        = each.value.description
  logic              = each.value.logic
  decision_strategy  = each.value.decisionStrategy

  dynamic "scope" {
    for_each = each.value.clientScope.scopes
    content {
      id       = data.keycloak_openid_client_scope.authz[scope.value.name].id
      required = scope.value.required
    }
  }
}

resource "keycloak_openid_client_time_policy" "this" {
  for_each = {
    for k, p in local.authz_policies :
    k => p
    if p.type == "time"
  }
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  description        = each.value.description
  logic              = each.value.logic
  decision_strategy  = each.value.decisionStrategy
  not_before         = each.value.time.notBefore
  not_on_or_after    = each.value.time.notOnOrAfter
  day_month          = each.value.time.dayMonth
  day_month_end      = each.value.time.dayMonthEnd
  month              = each.value.time.month
  month_end          = each.value.time.monthEnd
  year               = each.value.time.year
  year_end           = each.value.time.yearEnd
  hour               = each.value.time.hour
  hour_end           = each.value.time.hourEnd
  minute             = each.value.time.minute
  minute_end         = each.value.time.minuteEnd
}

resource "keycloak_openid_client_regex_policy" "this" {
  for_each = {
    for k, p in local.authz_policies :
    k => p
    if p.type == "regex"
  }
  realm_id                  = data.keycloak_realm.this.id
  resource_server_id        = keycloak_openid_client.this.resource_server_id
  name                      = each.key
  description               = each.value.description
  logic                     = each.value.logic
  decision_strategy         = each.value.decisionStrategy
  target_claim              = each.value.regex.targetClaim
  pattern                   = each.value.regex.pattern
  target_context_attributes = each.value.regex.targetContextAttributes
}

# Aggregates come after the plain policies they combine (validated: no aggregate of aggregates).
resource "keycloak_openid_client_aggregate_policy" "this" {
  for_each = {
    for k, p in local.authz_policies :
    k => p
    if p.type == "aggregate"
  }
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  description        = each.value.description
  logic              = each.value.logic
  decision_strategy  = each.value.decisionStrategy
  policies = [
    for n in each.value.aggregate.policies :
    local.authz_plain_policy_ids[n]
  ]
}

# --- permissions --------------------------------------------------------------------------

resource "keycloak_openid_client_authorization_permission" "this" {
  for_each           = local.authz_permissions
  realm_id           = data.keycloak_realm.this.id
  resource_server_id = keycloak_openid_client.this.resource_server_id
  name               = each.key
  type               = each.value.type
  description        = each.value.description
  decision_strategy  = each.value.decisionStrategy
  resource_type      = each.value.resourceType
  policies = [
    for n in each.value.policies :
    local.authz_policy_ids[n]
  ]
  resources = (
    length(each.value.resources) == 0
    ? null
    : [for n in each.value.resources : keycloak_openid_client_authorization_resource.this[n].id]
  )
  scopes = (
    length(each.value.scopes) == 0
    ? null
    : [for n in each.value.scopes : keycloak_openid_client_authorization_scope.this[n].id]
  )
}
