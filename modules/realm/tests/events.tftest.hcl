mock_provider "keycloak" {}

variables {
  name = "my-realm"
}

run "none_by_default" {
  command = plan

  assert {
    condition     = length(keycloak_realm_events.this) == 0
    error_message = "Expected no events resource when events is null."
  }
}

run "keeps_jboss_logging_by_default" {
  command = plan
  variables {
    events = {
      eventsEnabled = true
    }
  }

  assert {
    condition     = toset(keycloak_realm_events.this[0].events_listeners) == toset(["jboss-logging"])
    error_message = "Expected the jboss-logging listener to be kept when eventsListeners is unset."
  }

  assert {
    condition     = keycloak_realm_events.this[0].events_enabled == true
    error_message = "Expected events_enabled to be true."
  }
}

run "all_settings" {
  command = plan
  variables {
    events = {
      eventsListeners           = ["jboss-logging", "email"]
      eventsEnabled             = true
      eventsExpiration          = 604800
      enabledEventTypes         = ["LOGIN", "LOGIN_ERROR"]
      adminEventsEnabled        = true
      adminEventsDetailsEnabled = true
    }
  }

  assert {
    condition     = toset(keycloak_realm_events.this[0].events_listeners) == toset(["jboss-logging", "email"])
    error_message = "Expected the given listeners."
  }

  assert {
    condition     = keycloak_realm_events.this[0].events_expiration == 604800
    error_message = "Expected events_expiration to be 604800."
  }

  assert {
    condition     = toset(keycloak_realm_events.this[0].enabled_event_types) == toset(["LOGIN", "LOGIN_ERROR"])
    error_message = "Expected the given event types."
  }

  assert {
    condition     = keycloak_realm_events.this[0].admin_events_enabled == true && keycloak_realm_events.this[0].admin_events_details_enabled == true
    error_message = "Expected admin events and details to be enabled."
  }
}
