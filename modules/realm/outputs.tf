output "id" {
  description = "The realm's internal ID"
  value       = keycloak_realm.this.id
}

output "realm" {
  description = "The realm name"
  value       = keycloak_realm.this.realm
}