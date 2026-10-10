output "name" {
  description = "The workflow name."
  value       = keycloak_workflow.this.name
}

output "id" {
  description = "The workflow's Keycloak ID."
  value       = keycloak_workflow.this.id
}

output "errors" {
  description = "Errors Keycloak recorded for the workflow, e.g. a step type it does not know."
  value       = try(keycloak_workflow.this.state[0].errors, [])
}
