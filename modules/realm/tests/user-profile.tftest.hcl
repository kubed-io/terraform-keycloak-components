mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

run "none_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_realm_user_profile.this) == 0
    error_message = "Expected no user profile when user_profile is null."
  }
}

run "rejects_a_profile_without_username" {
  command = plan
  variables {
    user_profile = {
      attributes = [{ name = "email" }]
    }
  }

  expect_failures = [var.user_profile]
}

run "rejects_a_profile_without_email" {
  command = plan
  variables {
    user_profile = {
      attributes = [{ name = "username" }]
    }
  }

  expect_failures = [var.user_profile]
}

run "rejects_an_unknown_unmanaged_attribute_policy" {
  command = plan
  variables {
    user_profile = {
      unmanagedAttributePolicy = "SOMETIMES"
      attributes               = [{ name = "username" }, { name = "email" }]
    }
  }

  expect_failures = [var.user_profile]
}

run "defaults_plus_mailbox" {
  command = plan
  variables {
    user_profile = {
      unmanagedAttributePolicy = "ADMIN_VIEW"
      attributes = [
        {
          name        = "username"
          displayName = "$${username}"
          validators = {
            length                           = { min = "3", max = "255" }
            "username-prohibited-characters" = {}
          }
          permissions = { view = ["admin", "user"], edit = ["admin", "user"] }
        },
        {
          name             = "email"
          requiredForRoles = ["user"]
          validators       = { email = {}, length = { max = "255" } }
          permissions      = { view = ["admin", "user"], edit = ["admin", "user"] }
        },
        { name = "firstName", requiredForRoles = ["user"] },
        { name = "lastName", requiredForRoles = ["user"] },
        {
          name             = "mailbox"
          displayName      = "Mailbox"
          group            = "user-metadata"
          defaultValue     = "none"
          enabledWhenScope = ["email"]
          validators       = { email = {} }
          annotations      = { inputType = "html5-email" }
          permissions      = { view = ["admin", "user"], edit = ["admin"] }
        },
      ]
      groups = [
        {
          name               = "user-metadata"
          displayHeader      = "User metadata"
          displayDescription = "Attributes, which refer to user metadata"
          annotations        = { collapsed = "true" }
        },
      ]
    }
  }

  assert {
    condition     = keycloak_realm_user_profile.this[0].realm_id == keycloak_realm.this.id
    error_message = "Expected the profile on this realm."
  }

  assert {
    condition     = keycloak_realm_user_profile.this[0].unmanaged_attribute_policy == "ADMIN_VIEW"
    error_message = "Expected the unmanaged attribute policy."
  }

  assert {
    condition     = length(keycloak_realm_user_profile.this[0].attribute) == 5
    error_message = "Expected all five attributes."
  }

  assert {
    condition     = keycloak_realm_user_profile.this[0].attribute[0].display_name == "$${username}"
    error_message = "Expected a literal $${username} display name (Keycloak's message key)."
  }

  assert {
    condition     = keycloak_realm_user_profile.this[0].attribute[4].name == "mailbox"
    error_message = "Expected attribute order to be kept."
  }

  assert {
    condition     = toset(keycloak_realm_user_profile.this[0].attribute[4].permissions[0].edit) == toset(["admin"])
    error_message = "Expected mailbox to be admin-edit only."
  }

  assert {
    condition     = keycloak_realm_user_profile.this[0].attribute[4].default_value == "none"
    error_message = "Expected the default value."
  }

  assert {
    condition     = toset(keycloak_realm_user_profile.this[0].attribute[4].enabled_when_scope) == toset(["email"])
    error_message = "Expected enabledWhenScope."
  }

  assert {
    condition     = keycloak_realm_user_profile.this[0].attribute[4].annotations["inputType"] == "html5-email"
    error_message = "Expected the attribute annotations."
  }

  assert {
    condition = toset([
      for v in keycloak_realm_user_profile.this[0].attribute[0].validator :
      v.name
    ]) == toset(["length", "username-prohibited-characters"])
    error_message = "Expected one validator block per validators entry."
  }

  assert {
    condition = one([
      for v in keycloak_realm_user_profile.this[0].attribute[0].validator :
      v.config
      if v.name == "length"
    ]) == tomap({ min = "3", max = "255" })
    error_message = "Expected a validator's config to pass through."
  }

  assert {
    condition     = one(keycloak_realm_user_profile.this[0].group).annotations["collapsed"] == "true"
    error_message = "Expected the group annotations."
  }

  assert {
    condition     = one(keycloak_realm_user_profile.this[0].group).display_header == "User metadata"
    error_message = "Expected the group display header."
  }
}

run "attribute_without_permissions" {
  command = plan
  variables {
    user_profile = {
      attributes = [{ name = "username" }, { name = "email" }]
    }
  }

  assert {
    condition     = length(keycloak_realm_user_profile.this[0].attribute[0].permissions) == 0
    error_message = "Expected no permissions block when none is given (Keycloak's default applies)."
  }

  assert {
    condition     = length(keycloak_realm_user_profile.this[0].group) == 0
    error_message = "Expected no groups when none are given."
  }
}
