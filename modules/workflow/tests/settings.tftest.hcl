mock_provider "keycloak" {}

variables {
  realm = "my-realm"
  name  = "track-inactive-users"
  on    = "user-authenticated"
  steps = [
    { uses = "invite-user" },
  ]
}

run "conditions_and_enabled" {
  command = plan
  variables {
    conditions = "has-role(gold) and not is-member-of(/staff)"
    enabled    = false
  }

  assert {
    condition     = keycloak_workflow.this.conditions == "has-role(gold) and not is-member-of(/staff)"
    error_message = "Expected the conditions expression to pass through."
  }

  assert {
    condition     = keycloak_workflow.this.enabled == false
    error_message = "Expected the workflow to be disabled."
  }
}

run "no_schedule_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_workflow.this.schedule) == 0
    error_message = "Expected no schedule block when schedule is null."
  }
}

run "schedule" {
  command = plan
  variables {
    schedule = {
      after     = "1d"
      batchSize = 100
    }
  }

  assert {
    condition     = keycloak_workflow.this.schedule[0].after == "1d"
    error_message = "Expected the schedule interval."
  }

  assert {
    condition     = keycloak_workflow.this.schedule[0].batch_size == 100
    error_message = "Expected the schedule batch size."
  }
}

run "step_settings" {
  command = plan
  variables {
    steps = [
      {
        uses   = "notify-user"
        after  = "180d"
        config = { message = "We miss you." }
      },
      {
        uses     = "disable-user"
        after    = "7d"
        priority = 1
      },
    ]
  }

  assert {
    condition     = keycloak_workflow.this.step[0].after == "180d"
    error_message = "Expected the first step's delay."
  }

  assert {
    condition     = keycloak_workflow.this.step[0].config["message"] == "We miss you."
    error_message = "Expected the step config (Keycloak's `with`) to pass through."
  }

  assert {
    condition     = keycloak_workflow.this.step[1].uses == "disable-user"
    error_message = "Expected step order to be kept."
  }

  assert {
    condition     = keycloak_workflow.this.step[1].priority == "1"
    error_message = "Expected a numeric priority to reach the provider as a string."
  }
}

run "concurrency_unset" {
  command = plan

  assert {
    condition     = keycloak_workflow.this.restart_in_progress == null && keycloak_workflow.this.cancel_in_progress == null
    error_message = "Expected neither concurrency flag when concurrency is null."
  }
}

run "concurrency_restart" {
  command = plan
  variables {
    concurrency = "restart-in-progress"
  }

  assert {
    condition     = keycloak_workflow.this.restart_in_progress == "true"
    error_message = "Expected restart-in-progress to set restart_in_progress."
  }

  assert {
    condition     = keycloak_workflow.this.cancel_in_progress == null
    error_message = "Expected cancel_in_progress to stay unset."
  }
}

run "concurrency_cancel" {
  command = plan
  variables {
    concurrency = "cancel-in-progress"
  }

  assert {
    condition     = keycloak_workflow.this.cancel_in_progress == "true"
    error_message = "Expected cancel-in-progress to set cancel_in_progress."
  }

  assert {
    condition     = keycloak_workflow.this.restart_in_progress == null
    error_message = "Expected restart_in_progress to stay unset."
  }
}
