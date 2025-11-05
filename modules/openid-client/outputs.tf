output "name" {
  description = "The name of the client"
  value       = keycloak_openid_client.this.name
}

output "id" {
  description = "The ID of the client"
  value       = keycloak_openid_client.this.client_id
}

output "client_secret" {
  description = "The secret associated with this client"
  value       = keycloak_openid_client.this.client_secret
  sensitive   = true
}

output "resource_server_id" {
  description = "(Computed) When authorization is enabled for this client, this attribute is the unique ID for the client (the same value as the .id attribute)."
  value       = var.authorization != null ? keycloak_openid_client.this.resource_server_id : null
}

output "service_account_user_id" {
  description = "(Computed) When service accounts are enabled for this client, this attribute is the unique ID for the Keycloak user that represents this service account."
  value       = var.capabilities.serviceAccountsEnabled == true ? keycloak_openid_client.this.service_account_user_id : null
}

# only output this is var.permissions is not null
output "authorization_resource_server_id" {
  description = "(Computed) When permissions are defined for this client, this attribute is the unique ID for the authorization resource server."
  value       = var.permissions != null ? keycloak_openid_client_permissions.this[0].authorization_resource_server_id : null
}
