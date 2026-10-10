mock_provider "keycloak" {}

variables {
  realm = "my-realm"
  on    = "user-created"
  steps = [
    { uses = "invite-user" },
  ]
}

run "simple_workflow" {
  command = plan

  assert {
    condition     = keycloak_workflow.this.realm == "my-realm"
    error_message = "Expected the workflow in the given realm."
  }

  assert {
    condition     = keycloak_workflow.this.on == "user-created"
    error_message = "Expected the trigger expression to pass through."
  }

  assert {
    condition     = length(keycloak_workflow.this.step) == 1 && keycloak_workflow.this.step[0].uses == "invite-user"
    error_message = "Expected the single invite-user step."
  }

  assert {
    condition     = keycloak_workflow.this.name == "default"
    error_message = "Expected the name to default to the workspace name (`default` under tofu test)."
  }

  assert {
    condition     = output.name == "default"
    error_message = "Expected the name output to follow the workflow."
  }
}

run "named" {
  command = plan
  variables {
    name = "invite-new-people"
  }

  assert {
    condition     = keycloak_workflow.this.name == "invite-new-people"
    error_message = "Expected the given name to win over the workspace name."
  }
}
