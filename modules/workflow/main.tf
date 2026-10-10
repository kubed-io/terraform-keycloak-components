resource "keycloak_workflow" "this" {
  realm      = var.realm
  name       = coalesce(var.name, terraform.workspace)
  on         = var.on
  conditions = var.conditions
  enabled    = var.enabled

  # Keycloak's concurrency is one of two options; the provider exposes each as a "true" string.
  restart_in_progress = var.concurrency == "restart-in-progress" ? "true" : null
  cancel_in_progress  = var.concurrency == "cancel-in-progress" ? "true" : null

  dynamic "schedule" {
    for_each = var.schedule == null ? [] : [var.schedule]
    content {
      after      = schedule.value.after
      batch_size = schedule.value.batchSize
    }
  }

  dynamic "step" {
    for_each = var.steps
    content {
      uses     = step.value.uses
      after    = step.value.after
      priority = step.value.priority == null ? null : tostring(step.value.priority)
      config   = step.value.config
    }
  }
}
