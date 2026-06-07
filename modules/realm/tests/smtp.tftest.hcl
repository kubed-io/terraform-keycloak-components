mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

# The SMTP block is only emitted when var.smtp is supplied; the auth sub-block is
# only emitted when smtp_username is also supplied (creds come from a secret).

run "smtp_without_auth" {
  command = plan
  variables {
    smtp = {
      host            = "docker-mailserver.connect.svc.cluster.local"
      port            = 587
      from            = "noreply@mail.example.com"
      fromDisplayName = "Example"
      starttls        = true
    }
  }

  assert {
    condition     = length(keycloak_realm.this.smtp_server) == 1
    error_message = "Expected one smtp_server block."
  }

  assert {
    condition     = keycloak_realm.this.smtp_server[0].host == "docker-mailserver.connect.svc.cluster.local"
    error_message = "Expected the SMTP host to be set."
  }

  assert {
    condition     = keycloak_realm.this.smtp_server[0].port == "587"
    error_message = "Expected the SMTP port to be 587."
  }

  assert {
    condition     = keycloak_realm.this.smtp_server[0].starttls == true
    error_message = "Expected starttls to be true."
  }

  # No credentials → no auth sub-block.
  assert {
    condition     = length(keycloak_realm.this.smtp_server[0].auth) == 0
    error_message = "Expected no auth block when smtp_username is unset."
  }
}

run "smtp_with_auth" {
  command = plan
  variables {
    smtp = {
      host = "docker-mailserver.connect.svc.cluster.local"
      from = "noreply@mail.example.com"
    }
    smtp_username = "keycloak"
    smtp_password = "s3cr3t"
  }

  assert {
    condition     = length(keycloak_realm.this.smtp_server[0].auth) == 1
    error_message = "Expected an auth block when smtp_username is supplied."
  }

  assert {
    condition     = keycloak_realm.this.smtp_server[0].auth[0].username == "keycloak"
    error_message = "Expected the SMTP auth username to be wired through."
  }

  assert {
    condition     = keycloak_realm.this.smtp_server[0].auth[0].password == "s3cr3t"
    error_message = "Expected the SMTP auth password to be wired through."
  }
}
