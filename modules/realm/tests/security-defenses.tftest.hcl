mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

# security_defenses is only emitted when at least one of its sub-blocks (headers /
# brute_force_detection) is supplied; each sub-block is independently gated.

run "no_block_when_unset" {
  command = plan

  assert {
    condition     = length(keycloak_realm.this.security_defenses) == 0
    error_message = "Expected no security_defenses block when neither sub-block is set."
  }
}

run "brute_force_only" {
  command = plan
  variables {
    security_defenses = {
      bruteForceDetection = {
        maxLoginFailures        = 30
        permanentLockout        = false
        failureResetTimeSeconds = 43200
      }
    }
  }

  assert {
    condition     = length(keycloak_realm.this.security_defenses) == 1
    error_message = "Expected a security_defenses block."
  }

  assert {
    condition     = length(keycloak_realm.this.security_defenses[0].brute_force_detection) == 1
    error_message = "Expected a brute_force_detection sub-block."
  }

  assert {
    condition     = keycloak_realm.this.security_defenses[0].brute_force_detection[0].max_login_failures == 30
    error_message = "Expected max_login_failures to be 30."
  }

  # headers not supplied → no headers sub-block.
  assert {
    condition     = length(keycloak_realm.this.security_defenses[0].headers) == 0
    error_message = "Expected no headers sub-block when only brute force is set."
  }
}

run "headers_only" {
  command = plan
  variables {
    security_defenses = {
      headers = {
        xFrameOptions           = "DENY"
        contentSecurityPolicy   = "frame-src 'self'; frame-ancestors 'self'; object-src 'none';"
        strictTransportSecurity = "max-age=31536000; includeSubDomains"
      }
    }
  }

  assert {
    condition     = length(keycloak_realm.this.security_defenses[0].headers) == 1
    error_message = "Expected a headers sub-block."
  }

  assert {
    condition     = keycloak_realm.this.security_defenses[0].headers[0].x_frame_options == "DENY"
    error_message = "Expected x_frame_options to be 'DENY'."
  }

  assert {
    condition     = length(keycloak_realm.this.security_defenses[0].brute_force_detection) == 0
    error_message = "Expected no brute_force_detection sub-block when only headers are set."
  }
}

run "headers_and_brute_force" {
  command = plan
  variables {
    security_defenses = {
      headers             = { xFrameOptions = "SAMEORIGIN" }
      bruteForceDetection = { maxLoginFailures = 10 }
    }
  }

  assert {
    condition     = length(keycloak_realm.this.security_defenses[0].headers) == 1 && length(keycloak_realm.this.security_defenses[0].brute_force_detection) == 1
    error_message = "Expected both sub-blocks to be emitted."
  }
}
