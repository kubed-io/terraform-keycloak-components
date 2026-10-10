mock_provider "keycloak" {}

variables {
  realm = "my-realm"
  on    = "user-created"
  steps = [
    { uses = "invite-user" },
  ]
}

run "rejects_no_steps" {
  command = plan
  variables {
    steps = []
  }

  expect_failures = [var.steps]
}

run "rejects_unknown_concurrency" {
  command = plan
  variables {
    concurrency = "queue"
  }

  expect_failures = [var.concurrency]
}
