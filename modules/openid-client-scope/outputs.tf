output "name" {
  description = "The client scope name."
  value       = keycloak_openid_client_scope.this.name
}

output "id" {
  description = "The client scope's Keycloak ID, used to attach protocol mappers (`client_scope_id`)."
  value       = keycloak_openid_client_scope.this.id
}
