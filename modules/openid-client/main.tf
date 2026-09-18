locals {
  id = coalesce(var.id, terraform.workspace)
  name = coalesce(
    var.name,
    title(replace(local.id, "[^a-zA-Z0-9]", " "))
  )

  # --- role mappers (role-mappers.tf, role-sync.tf) -------------------------------------
  ldap_mappers    = [for m in var.role_mappers : m if m.type == "ldap"]
  generic_mappers = [for m in var.role_mappers : m if m.type == "generic"]
  has_ldap        = length(local.ldap_mappers) > 0

  # Distinct LDAP user-federation NAMES referenced (default to the realm name). One
  # components lookup per name (deduped), regardless of how many mappers use it.
  fed_names = toset([for m in local.ldap_mappers : coalesce(m.ldap.federationId, var.realm)])

  # federation name → GUID (id of the matching UserStorageProvider component)
  fed_guid = {
    for n in local.fed_names :
    n => jsondecode(data.http.federation[n].response_body)[0].id
  }

  # --- Keycloak Admin REST API ---------------------------------------------------------
  # The keycloak provider covers neither the federation `components` lookup (role-mappers.tf)
  # nor the mapper sync (role-sync.tf), so both go over the Admin API with a master-realm
  # token. Prefer the Crossplane provider-mounted credential files; fall back to var.creds
  # for standalone TF / tests. try() handles the file being absent (file() hard-errors on a
  # missing file).
  #
  # All of it is INERT without an ldap-type mapper: kc_creds is null, the token has count 0,
  # and the dependent data sources have an empty for_each — so a client with no (or only
  # generic) role mappers needs no creds and makes no http calls.
  kc_creds = local.has_ldap ? {
    url       = nonsensitive(try(file("url"), var.creds.url))
    client_id = nonsensitive(try(file("client_id"), var.creds.client_id))
    username  = try(file("username"), var.creds.username)
    password  = try(file("password"), var.creds.password)
  } : null

  admin_token = local.has_ldap ? try(jsondecode(data.http.token[0].response_body).access_token, "") : ""
}

data "keycloak_realm" "this" {
  realm = var.realm
}

# Admin token (master realm, password grant) — only when something needs the Admin API.
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

# Resolve each LDAP federation NAME → component ([0].id is the GUID local.fed_guid keys on,
# which role-mappers.tf needs for ldap_user_federation_id).
data "http" "federation" {
  for_each = local.fed_names
  url      = "${local.kc_creds.url}/admin/realms/${var.realm}/components?name=${urlencode(each.value)}&type=org.keycloak.storage.UserStorageProvider"
  request_headers = {
    Authorization = "Bearer ${local.admin_token}"
  }
}
