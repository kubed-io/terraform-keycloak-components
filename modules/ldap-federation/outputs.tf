output "id" {
  description = "The ID (GUID) of the LDAP user federation. Needed as ldap_user_federation_id by any keycloak_ldap_role_mapper declared outside this module (e.g. an OpenidClient-side roleMapper)."
  value       = keycloak_ldap_user_federation.this.id
}

output "realm" {
  description = "The realm this federation lives in. Convenience for consumers that need both realm + federation id to attach a mapper."
  value       = var.realm
}

output "name" {
  description = "The federation's display name."
  value       = local.name
}
