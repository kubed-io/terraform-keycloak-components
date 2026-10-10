variable "name" {
  description = "The workflow name, unique in the realm. Defaults to the workspace name."
  type        = string
  default     = null
}

variable "realm" {
  description = "The realm the workflow runs in."
  type        = string
}

variable "on" {
  description = "The event expression that starts the workflow, e.g. `user-created` or `user-group-membership-added(/staff) or user-role-granted(admin)`."
  type        = string
}

variable "conditions" {
  description = "Keycloak's `if`: an expression the user must satisfy for the workflow to start, e.g. `has-user-attribute(plan=gold) and not is-member-of(/staff)`. Null always starts it."
  type        = string
  default     = null
}

variable "enabled" {
  description = "When false, no new executions start and running ones pause. Provider default: true."
  type        = bool
  default     = null
}

variable "concurrency" {
  description = "What a new trigger does to an execution already running for the same user: `restart-in-progress` (start over) or `cancel-in-progress` (drop it). Null leaves Keycloak's default."
  type        = string
  default     = null

  validation {
    condition = (
      var.concurrency == null
      ? true
      : contains(["restart-in-progress", "cancel-in-progress"], var.concurrency)
    )
    error_message = "concurrency must be restart-in-progress or cancel-in-progress."
  }
}

variable "schedule" {
  description = "Also run every `after` (e.g. `1d`) over up to `batchSize` users that satisfy `conditions`. One per workflow."
  type = object({
    after     = string
    batchSize = optional(number, null)
  })
  default = null
}

variable "steps" {
  description = "The steps, run in order. `uses` is the step type (invite-user, notify-user, add-required-action, grant-role, join-group, disable-user, delete-user, restart, …); `after` delays it (e.g. `30d`); `config` is the step's own settings (Keycloak's `with`)."
  type = list(object({
    uses     = string
    after    = optional(string, null)
    priority = optional(number, null)
    config   = optional(map(string), null)
  }))

  validation {
    condition     = length(var.steps) > 0
    error_message = "A workflow needs at least one step."
  }
}
