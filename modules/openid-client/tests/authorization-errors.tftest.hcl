mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
}

variables {
  realm        = "my-realm"
  id           = "billing"
  access_type  = "CONFIDENTIAL"
  capabilities = { serviceAccountsEnabled = true }
}

run "accepts_a_valid_setup" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      scopes                = [{ name = "view" }]
      resources             = [{ name = "invoices", scopes = ["view"] }]
      policies              = [{ name = "readers", type = "user", user = { users = ["alice"] } }]
      permissions           = [{ name = "read", resources = ["invoices"], policies = ["readers"] }]
    }
  }
}

run "needs_a_confidential_client" {
  command = plan
  variables {
    access_type   = "PUBLIC"
    authorization = { policyEnforcementMode = "ENFORCING" }
  }
  expect_failures = [var.authorization]
}

run "needs_service_accounts" {
  command = plan
  variables {
    capabilities  = {}
    authorization = { policyEnforcementMode = "ENFORCING" }
  }
  expect_failures = [var.authorization]
}

run "rejects_an_unknown_policy_type" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      policies              = [{ name = "p", type = "javascript" }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_a_policy_without_its_type_block" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      policies              = [{ name = "p", type = "role" }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_duplicate_names" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      policies = [
        { name = "p", type = "user", user = { users = ["alice"] } },
        { name = "p", type = "user", user = { users = ["bob"] } },
      ]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_a_bad_logic" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      policies              = [{ name = "p", type = "user", logic = "MAYBE", user = { users = ["alice"] } }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_a_bad_decision_strategy" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      permissions           = [{ name = "x", resourceType = "urn:t", decisionStrategy = "MAJORITY" }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_a_resource_with_an_unknown_scope" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      resources             = [{ name = "invoices", scopes = ["view"] }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_an_aggregate_of_an_unknown_policy" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      policies              = [{ name = "a", type = "aggregate", aggregate = { policies = ["missing"] } }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_an_aggregate_of_an_aggregate" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      policies = [
        { name = "u", type = "user", user = { users = ["alice"] } },
        { name = "a1", type = "aggregate", aggregate = { policies = ["u"] } },
        { name = "a2", type = "aggregate", aggregate = { policies = ["a1"] } },
      ]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_a_permission_with_an_unknown_reference" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      permissions           = [{ name = "x", resources = ["missing"], policies = ["missing"] }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_a_resource_permission_without_a_target" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      permissions           = [{ name = "x" }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_a_permission_with_resources_and_resource_type" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      resources             = [{ name = "invoices" }]
      permissions           = [{ name = "x", resources = ["invoices"], resourceType = "urn:t" }]
    }
  }
  expect_failures = [var.authorization]
}

run "rejects_a_scope_permission_without_scopes" {
  command = plan
  variables {
    authorization = {
      policyEnforcementMode = "ENFORCING"
      resources             = [{ name = "invoices" }]
      permissions           = [{ name = "x", type = "scope", resources = ["invoices"] }]
    }
  }
  expect_failures = [var.authorization]
}
