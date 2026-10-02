mock_provider "keycloak" {
  mock_data "keycloak_realm" {
    defaults = {
      id = "example-realm-id"
    }
  }
  mock_data "keycloak_openid_client" {
    defaults = {
      id = "grafana-uuid"
    }
  }
  mock_resource "keycloak_openid_client" {
    defaults = {
      id                      = "drupal-uuid"
      service_account_user_id = "drupal-sa-user"
    }
  }
}

variables {
  realm        = "my-realm"
  id           = "drupal"
  access_type  = "CONFIDENTIAL"
  capabilities = { serviceAccountsEnabled = true }
}

run "none_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_openid_client_service_account_realm_role.this) == 0 && length(keycloak_openid_client_service_account_role.this) == 0
    error_message = "Expected no service account roles when unset."
  }
}

run "realm_and_client_roles" {
  command = apply
  variables {
    service_account_roles = [
      { name = "foo" },
      { name = "viewer", client = "grafana" },
      { name = "editor", client = "drupal" },
    ]
  }

  assert {
    condition     = keycloak_openid_client_service_account_realm_role.this["foo"].role == "foo" && keycloak_openid_client_service_account_realm_role.this["foo"].service_account_user_id == "drupal-sa-user"
    error_message = "Expected the realm role on this client's service account user."
  }

  assert {
    condition     = keycloak_openid_client_service_account_role.this["grafana/viewer"].client_id == "grafana-uuid" && keycloak_openid_client_service_account_role.this["grafana/viewer"].role == "viewer"
    error_message = "Expected the grafana role with grafana's internal ID."
  }

  assert {
    condition     = keycloak_openid_client_service_account_role.this["drupal/editor"].client_id == "drupal-uuid"
    error_message = "Expected a role of this client to use this client's ID, not a lookup."
  }

  assert {
    condition     = keys(data.keycloak_openid_client.sa_role_client) == ["grafana"]
    error_message = "Expected only grafana to be looked up; this client must not look itself up."
  }
}

run "rejects_without_service_accounts" {
  command = plan
  variables {
    capabilities          = {}
    service_account_roles = [{ name = "foo" }]
  }
  expect_failures = [var.service_account_roles]
}

run "rejects_public_client" {
  command = plan
  variables {
    access_type           = "PUBLIC"
    service_account_roles = [{ name = "foo" }]
  }
  expect_failures = [var.service_account_roles]
}

run "rejects_duplicates" {
  command = plan
  variables {
    service_account_roles = [{ name = "foo" }, { name = "foo" }]
  }
  expect_failures = [var.service_account_roles]
}
