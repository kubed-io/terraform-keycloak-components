# Force each ldap role mapper to import its roles — the Admin console's "Sync LDAP roles
# to Keycloak" button, over the token minted in role-mappers.tf.
#
# An LDAP_ONLY mapper materialises the Keycloak-side client role LAZILY, on the first load
# of a user who already holds it. A new role's only member is the owner seed
# (uid=<app>,ou=services), which sits outside the federation's users DN — so nothing ever
# triggers it: the role isn't grantable until someone holds it, and nobody can hold it
# until it's grantable. Under role_attribute_strict that locks a whole tier out of the app.
#
# A data source, not a resource: roles appear in LDAP without anything on the Keycloak side
# changing, so there is no config value to key triggers off — the module cannot see LDAP.
# Re-reading every plan is the only correct cadence. Idempotent and cheap (one subtree
# search, upsert by name). Import-only: never removes.
#
# Do NOT expose the response as an output — `added` flips between runs and reads as a
# permanent diff.
data "http" "role_sync" {
  for_each = keycloak_ldap_role_mapper.this

  method = "POST"
  url    = "${local.kc_creds.url}/admin/realms/${var.realm}/user-storage/${each.value.ldap_user_federation_id}/mappers/${each.value.id}/sync?direction=fedToKeycloak"
  request_headers = {
    Authorization = "Bearer ${local.admin_token}"
  }

  # hashicorp/http does not fail on a non-2xx — without this a broken sync is silent.
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "LDAP role mapper sync failed (HTTP ${self.status_code}): ${self.url}"
    }
  }
}
