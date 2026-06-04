# Role mappers attached to this client. Two kinds (var.role_mappers[*].type):
#   ldap    → keycloak_ldap_role_mapper (cn=<role> children under baseDn → CLIENT roles
#             of THIS client; federation GUID resolved by name via the Admin REST API)
#   generic → keycloak_generic_client_role_mapper (add an existing role to this client's
#             scope mappings)
#
# Everything LDAP-specific (the http calls + admin creds) is INERT unless at least one
# ldap-type mapper exists: kc_creds is null, the data sources have empty count/for_each,
# so a client with no (or only generic) mappers needs no creds and makes no http calls.

locals {
  ldap_mappers    = [for m in var.role_mappers : m if m.type == "ldap"]
  generic_mappers = [for m in var.role_mappers : m if m.type == "generic"]
  has_ldap        = length(local.ldap_mappers) > 0

  # Distinct LDAP user-federation NAMES referenced (default to the realm name). One
  # components lookup per name (deduped), regardless of how many mappers use it.
  fed_names = toset([for m in local.ldap_mappers : coalesce(m.ldap.federationId, var.realm)])

  # Admin auth for the token call — only computed when an ldap mapper exists. Prefer
  # the Crossplane provider-mounted files; fall back to var.creds for standalone TF /
  # tests. try() handles the file being absent (file() hard-errors on a missing file).
  kc_creds = local.has_ldap ? {
    url       = nonsensitive(try(file("url"), var.creds.url))
    client_id = nonsensitive(try(file("client_id"), var.creds.client_id))
    username  = try(file("username"), var.creds.username)
    password  = try(file("password"), var.creds.password)
  } : null

  admin_token = local.has_ldap ? try(jsondecode(data.http.token[0].response_body).access_token, "") : ""

  # federation name → GUID (id of the matching UserStorageProvider component)
  fed_guid = {
    for n in local.fed_names :
    n => jsondecode(data.http.federation[n].response_body)[0].id
  }
}

# 1) admin token (master realm, password grant) — only when an ldap mapper exists.
data "http" "token" {
  count  = local.has_ldap ? 1 : 0
  url    = "${local.kc_creds.url}/realms/master/protocol/openid-connect/token"
  method = "POST"
  request_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
  }
  request_body = join("&", [
    "client_id=${urlencode(local.kc_creds.client_id)}",
    "grant_type=password",
    "username=${urlencode(local.kc_creds.username)}",
    "password=${urlencode(local.kc_creds.password)}",
  ])
}

# 2) resolve each federation NAME → component ([0].id is the GUID we need).
data "http" "federation" {
  for_each = local.fed_names
  url      = "${local.kc_creds.url}/admin/realms/${var.realm}/components?name=${urlencode(each.value)}&type=org.keycloak.storage.UserStorageProvider"
  request_headers = {
    Authorization = "Bearer ${local.admin_token}"
  }
}

# LDAP role mappers → CLIENT roles of THIS client. Because the mapper is bound to this
# client (client_id set), Keycloak requires use_realm_roles_mapping = false.
resource "keycloak_ldap_role_mapper" "this" {
  for_each = { for m in local.ldap_mappers : coalesce(m.name, m.type) => m }

  realm_id                = data.keycloak_realm.this.id
  ldap_user_federation_id = local.fed_guid[coalesce(each.value.ldap.federationId, var.realm)]
  name                    = each.key

  ldap_roles_dn                  = each.value.ldap.baseDn
  role_name_ldap_attribute       = each.value.ldap.nameAttribute
  role_object_classes            = each.value.ldap.objectClasses
  membership_ldap_attribute      = each.value.ldap.membershipAttribute
  membership_attribute_type      = each.value.ldap.membershipAttributeType
  membership_user_ldap_attribute = each.value.ldap.membershipUserAttribute
  user_roles_retrieve_strategy   = each.value.ldap.userRolesRetrieveStrategy
  memberof_ldap_attribute        = each.value.ldap.memberofAttribute
  mode                           = each.value.ldap.mode
  roles_ldap_filter              = each.value.ldap.searchFilter

  use_realm_roles_mapping = false
  client_id               = keycloak_openid_client.this.client_id
}

# Generic role mappers → add an existing role (by id) to THIS client's scope.
resource "keycloak_generic_role_mapper" "this" {
  for_each = { for m in local.generic_mappers : coalesce(m.name, m.type) => m }

  realm_id  = data.keycloak_realm.this.id
  client_id = keycloak_openid_client.this.id
  role_id   = each.value.generic.roleId
}
