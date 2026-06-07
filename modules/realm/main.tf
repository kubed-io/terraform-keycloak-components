resource "keycloak_realm" "this" {
  realm             = coalesce(var.name, terraform.workspace)
  enabled           = var.enabled
  display_name      = title(coalesce(var.display_name, var.name))
  display_name_html = coalesce(var.display_name_html, var.display_name, var.name)

  # --- General (top-level) ---
  ssl_required                  = var.ssl_required
  user_managed_access           = var.user_managed_access
  organizations_enabled         = var.organizations_enabled
  admin_permissions_enabled     = var.admin_permissions_enabled
  internal_id                   = var.internal_id
  terraform_deletion_protection = var.terraform_deletion_protection
  attributes                    = var.attributes

  default_default_client_scopes  = var.default_default_client_scopes
  default_optional_client_scopes = var.default_optional_client_scopes

  # --- Themes ---
  login_theme   = var.themes.loginTheme
  account_theme = var.themes.accountTheme
  admin_theme   = var.themes.adminTheme
  email_theme   = var.themes.emailTheme

  # --- Login ---
  registration_allowed           = var.login.registrationAllowed
  registration_email_as_username = var.login.registrationEmailAsUsername
  edit_username_allowed          = var.login.editUsernameAllowed
  reset_password_allowed         = var.login.resetPasswordAllowed
  remember_me                    = var.login.rememberMe
  verify_email                   = var.login.verifyEmail
  login_with_email_allowed       = var.login.loginWithEmailAllowed
  duplicate_emails_allowed       = var.login.duplicateEmailsAllowed

  # --- Tokens / Sessions ---
  default_signature_algorithm              = var.tokens.defaultSignatureAlgorithm
  revoke_refresh_token                     = var.tokens.revokeRefreshToken
  refresh_token_max_reuse                  = var.tokens.refreshTokenMaxReuse
  sso_session_idle_timeout                 = var.tokens.ssoSessionIdleTimeout
  sso_session_max_lifespan                 = var.tokens.ssoSessionMaxLifespan
  sso_session_idle_timeout_remember_me     = var.tokens.ssoSessionIdleTimeoutRememberMe
  sso_session_max_lifespan_remember_me     = var.tokens.ssoSessionMaxLifespanRememberMe
  offline_session_idle_timeout             = var.tokens.offlineSessionIdleTimeout
  offline_session_max_lifespan             = var.tokens.offlineSessionMaxLifespan
  offline_session_max_lifespan_enabled     = var.tokens.offlineSessionMaxLifespanEnabled
  client_session_idle_timeout              = var.tokens.clientSessionIdleTimeout
  client_session_max_lifespan              = var.tokens.clientSessionMaxLifespan
  access_token_lifespan                    = var.tokens.accessTokenLifespan
  access_token_lifespan_for_implicit_flow  = var.tokens.accessTokenLifespanForImplicitFlow
  access_code_lifespan                     = var.tokens.accessCodeLifespan
  access_code_lifespan_login               = var.tokens.accessCodeLifespanLogin
  access_code_lifespan_user_action         = var.tokens.accessCodeLifespanUserAction
  action_token_generated_by_user_lifespan  = var.tokens.actionTokenGeneratedByUserLifespan
  action_token_generated_by_admin_lifespan = var.tokens.actionTokenGeneratedByAdminLifespan
  oauth2_device_code_lifespan              = var.tokens.oauth2DeviceCodeLifespan
  oauth2_device_polling_interval           = var.tokens.oauth2DevicePollingInterval

  # --- Authentication → Policies (password policy is a flat arg) ---
  password_policy = var.policies.passwordPolicy

  # --- Email / SMTP (single nested block; auth creds from sensitive vars) ---
  dynamic "smtp_server" {
    for_each = var.smtp != null ? [var.smtp] : []
    content {
      host                  = smtp_server.value.host
      port                  = smtp_server.value.port
      from                  = smtp_server.value.from
      from_display_name     = smtp_server.value.fromDisplayName
      reply_to              = smtp_server.value.replyTo
      reply_to_display_name = smtp_server.value.replyToDisplayName
      envelope_from         = smtp_server.value.envelopeFrom
      starttls              = smtp_server.value.starttls
      ssl                   = smtp_server.value.ssl
      allow_utf8            = smtp_server.value.allowUtf8

      dynamic "auth" {
        for_each = var.smtp_username != null ? [1] : []
        content {
          username = var.smtp_username
          password = var.smtp_password
        }
      }
    }
  }

  # --- Localization / internationalization ---
  dynamic "internationalization" {
    for_each = var.internationalization != null ? [var.internationalization] : []
    content {
      supported_locales = internationalization.value.supportedLocales
      default_locale    = internationalization.value.defaultLocale
    }
  }

  # --- Security Defenses (headers + brute force) ---
  dynamic "security_defenses" {
    for_each = (var.security_defenses.headers != null ||
    var.security_defenses.bruteForceDetection != null) ? [var.security_defenses] : []
    content {
      dynamic "headers" {
        for_each = security_defenses.value.headers != null ? [security_defenses.value.headers] : []
        content {
          x_frame_options                     = headers.value.xFrameOptions
          content_security_policy             = headers.value.contentSecurityPolicy
          content_security_policy_report_only = headers.value.contentSecurityPolicyReportOnly
          x_content_type_options              = headers.value.xContentTypeOptions
          x_robots_tag                        = headers.value.xRobotsTag
          x_xss_protection                    = headers.value.xXssProtection
          strict_transport_security           = headers.value.strictTransportSecurity
          referrer_policy                     = headers.value.referrerPolicy
        }
      }
      dynamic "brute_force_detection" {
        for_each = security_defenses.value.bruteForceDetection != null ? [security_defenses.value.bruteForceDetection] : []
        content {
          permanent_lockout                = brute_force_detection.value.permanentLockout
          max_temporary_lockouts           = brute_force_detection.value.maxTemporaryLockouts
          max_login_failures               = brute_force_detection.value.maxLoginFailures
          wait_increment_seconds           = brute_force_detection.value.waitIncrementSeconds
          quick_login_check_milli_seconds  = brute_force_detection.value.quickLoginCheckMilliSeconds
          minimum_quick_login_wait_seconds = brute_force_detection.value.minimumQuickLoginWaitSeconds
          max_failure_wait_seconds         = brute_force_detection.value.maxFailureWaitSeconds
          failure_reset_time_seconds       = brute_force_detection.value.failureResetTimeSeconds
        }
      }
    }
  }

  # --- Authentication → Policies: OTP ---
  dynamic "otp_policy" {
    for_each = var.policies.otpPolicy != null ? [var.policies.otpPolicy] : []
    content {
      type              = otp_policy.value.type
      algorithm         = otp_policy.value.algorithm
      digits            = otp_policy.value.digits
      initial_counter   = otp_policy.value.initialCounter
      look_ahead_window = otp_policy.value.lookAheadWindow
      period            = otp_policy.value.period
      code_reusable     = otp_policy.value.codeReusable
    }
  }

  # --- Authentication → Policies: WebAuthn ---
  dynamic "web_authn_policy" {
    for_each = var.policies.webAuthnPolicy != null ? [var.policies.webAuthnPolicy] : []
    content {
      relying_party_entity_name         = web_authn_policy.value.relyingPartyEntityName
      relying_party_id                  = web_authn_policy.value.relyingPartyId
      signature_algorithms              = web_authn_policy.value.signatureAlgorithms
      attestation_conveyance_preference = web_authn_policy.value.attestationConveyancePreference
      authenticator_attachment          = web_authn_policy.value.authenticatorAttachment
      require_resident_key              = web_authn_policy.value.requireResidentKey
      user_verification_requirement     = web_authn_policy.value.userVerificationRequirement
      create_timeout                    = web_authn_policy.value.createTimeout
      avoid_same_authenticator_register = web_authn_policy.value.avoidSameAuthenticatorRegister
      acceptable_aaguids                = web_authn_policy.value.acceptableAaguids
      extra_origins                     = web_authn_policy.value.extraOrigins
    }
  }

  # --- Authentication → Policies: WebAuthn Passwordless ---
  dynamic "web_authn_passwordless_policy" {
    for_each = var.policies.webAuthnPasswordlessPolicy != null ? [var.policies.webAuthnPasswordlessPolicy] : []
    content {
      relying_party_entity_name         = web_authn_passwordless_policy.value.relyingPartyEntityName
      relying_party_id                  = web_authn_passwordless_policy.value.relyingPartyId
      signature_algorithms              = web_authn_passwordless_policy.value.signatureAlgorithms
      attestation_conveyance_preference = web_authn_passwordless_policy.value.attestationConveyancePreference
      authenticator_attachment          = web_authn_passwordless_policy.value.authenticatorAttachment
      require_resident_key              = web_authn_passwordless_policy.value.requireResidentKey
      user_verification_requirement     = web_authn_passwordless_policy.value.userVerificationRequirement
      create_timeout                    = web_authn_passwordless_policy.value.createTimeout
      avoid_same_authenticator_register = web_authn_passwordless_policy.value.avoidSameAuthenticatorRegister
      acceptable_aaguids                = web_authn_passwordless_policy.value.acceptableAaguids
      extra_origins                     = web_authn_passwordless_policy.value.extraOrigins
      passwordless_passkeys_enabled     = web_authn_passwordless_policy.value.passwordlessPasskeysEnabled
    }
  }
}
