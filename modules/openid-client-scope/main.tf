locals {
  name = coalesce(var.name, terraform.workspace)
}

data "keycloak_realm" "this" {
  realm = var.realm
}

resource "keycloak_openid_client_scope" "this" {
  realm_id                            = data.keycloak_realm.this.id
  name                                = local.name
  description                         = var.description
  consent_screen_text                 = var.consent_screen_text
  include_in_token_scope              = var.include_in_token_scope
  include_in_openid_provider_metadata = var.include_in_openid_provider_metadata
  gui_order                           = var.gui_order
  extra_config                        = var.extra_config
}
