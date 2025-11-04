resource "keycloak_openid_client" "this" {
  realm_id  = data.keycloak_realm.this.id
  client_id = local.id

  name        = local.name
  description = var.description
  enabled     = var.enabled

  access_type               = var.access_type
  always_display_in_console = var.always_display_in_console

  # Access Settings
  root_url            = var.access_settings.rootUrl
  admin_url           = var.access_settings.adminUrl
  base_url            = var.access_settings.baseUrl
  valid_redirect_uris = var.access_settings.redirectUris
  web_origins         = var.access_settings.webOrigins

  # Capabilities
  standard_flow_enabled                      = var.capabilities.standardFlowEnabled
  implicit_flow_enabled                      = var.capabilities.implicitFlowEnabled
  direct_access_grants_enabled               = var.capabilities.directAccessGrantsEnabled
  service_accounts_enabled                   = var.capabilities.serviceAccountsEnabled
  oauth2_device_authorization_grant_enabled  = var.capabilities.oauth2DeviceAuthorizationGrantEnabled
  backchannel_logout_session_required        = var.logout.backchannelLogoutSessionRequired
  backchannel_logout_revoke_offline_sessions = var.logout.backchannelLogoutRevokeOfflineSessions
  pkce_code_challenge_method                 = var.capabilities.pkceCodeChallengeMethod

  # Login Settings
  login_theme               = var.login.theme
  consent_required          = var.login.consentRequired
  display_on_consent_screen = var.login.displayOnConsentScreen
  consent_screen_text       = var.login.consentScreentText

  # Logout Settings
  frontchannel_logout_enabled = var.logout.frontChannelLogoutEnabled
  backchannel_logout_url      = var.logout.backchannelLogoutUrl
  frontchannel_logout_url     = var.logout.frontchannelLogoutUrl

  # Authorization
  dynamic "authorization" {
    for_each = var.authorization != null ? [var.authorization] : []
    content {
      policy_enforcement_mode          = authorization.value.policyEnforcementMode
      decision_strategy                = authorization.value.decisionStrategy
      allow_remote_resource_management = authorization.value.allowRemoteResourceManagement
      keep_defaults                    = authorization.value.keepDefaults
    }
  }

  # Extra configuration
  extra_config = var.extra_config
}