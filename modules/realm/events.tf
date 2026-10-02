resource "keycloak_realm_events" "this" {
  count    = var.events == null ? 0 : 1
  realm_id = keycloak_realm.this.id

  events_listeners             = var.events.eventsListeners
  events_enabled               = var.events.eventsEnabled
  events_expiration            = var.events.eventsExpiration
  enabled_event_types          = var.events.enabledEventTypes
  admin_events_enabled         = var.events.adminEventsEnabled
  admin_events_details_enabled = var.events.adminEventsDetailsEnabled
}
