variable "name" {
  description = "The name of the realm."
  type        = string
}

variable "display_name" {
  description = "The display name of the realm."
  type        = string
  default     = null
}

variable "display_name_html" {
  description = "The HTML display name of the realm."
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the realm is enabled."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Nested-by-UI-tab inputs. Each variable mirrors a Keycloak admin-UI tab; the
# resource (main.tf) flattens these to keycloak_realm's flat top-level args.
# Keys are camelCase mirrors of the CRD spec. Every key is optional(..., null),
# so unset keys are always present-but-null (HCL never drops declared keys) and
# main.tf can reference var.themes.loginTheme directly — no try() needed.
# The always-present groups default to {}; the dynamic-block groups
# (smtp / internationalization / security_defenses sub-blocks) default to null
# so the block is only emitted when the caller supplies it.
# ---------------------------------------------------------------------------

# --- Realm Settings → Themes ---
variable "themes" {
  description = "Themes tab: login/account/admin/email theme names."
  type = object({
    loginTheme   = optional(string, null)
    accountTheme = optional(string, null)
    adminTheme   = optional(string, null)
    emailTheme   = optional(string, null)
  })
  default = {}
}

# --- Realm Settings → Login ---
variable "login" {
  description = "Login tab booleans (Require SSL is General/top-level, not here)."
  type = object({
    registrationAllowed         = optional(bool, null)
    registrationEmailAsUsername = optional(bool, null)
    editUsernameAllowed         = optional(bool, null)
    resetPasswordAllowed        = optional(bool, null)
    rememberMe                  = optional(bool, null)
    verifyEmail                 = optional(bool, null)
    loginWithEmailAllowed       = optional(bool, null)
    duplicateEmailsAllowed      = optional(bool, null)
  })
  default = {}
}

# --- Realm Settings → Tokens (sessions + token lifespans) ---
# Duration values are Go-duration strings (e.g. "30m", "1h"); the rest are ints.
variable "tokens" {
  description = "Tokens/Sessions tab: session timeouts and token lifespans."
  type = object({
    defaultSignatureAlgorithm           = optional(string, null)
    revokeRefreshToken                  = optional(bool, null)
    refreshTokenMaxReuse                = optional(number, null)
    ssoSessionIdleTimeout               = optional(string, null)
    ssoSessionMaxLifespan               = optional(string, null)
    ssoSessionIdleTimeoutRememberMe     = optional(string, null)
    ssoSessionMaxLifespanRememberMe     = optional(string, null)
    offlineSessionIdleTimeout           = optional(string, null)
    offlineSessionMaxLifespan           = optional(string, null)
    offlineSessionMaxLifespanEnabled    = optional(bool, null)
    clientSessionIdleTimeout            = optional(string, null)
    clientSessionMaxLifespan            = optional(string, null)
    accessTokenLifespan                 = optional(string, null)
    accessTokenLifespanForImplicitFlow  = optional(string, null)
    accessCodeLifespan                  = optional(string, null)
    accessCodeLifespanLogin             = optional(string, null)
    accessCodeLifespanUserAction        = optional(string, null)
    actionTokenGeneratedByUserLifespan  = optional(string, null)
    actionTokenGeneratedByAdminLifespan = optional(string, null)
    oauth2DeviceCodeLifespan            = optional(string, null)
    oauth2DevicePollingInterval         = optional(number, null)
  })
  default = {}
}

# --- Realm Settings → Email (SMTP) ---
# auth username/password are NOT here — they arrive via the sensitive
# smtp_username/smtp_password vars below (wired from a secret by the composition).
variable "smtp" {
  description = "Email tab SMTP server settings (auth creds come from smtp_username/smtp_password)."
  type = object({
    host               = string
    port               = optional(number, null)
    from               = string
    fromDisplayName    = optional(string, null)
    replyTo            = optional(string, null)
    replyToDisplayName = optional(string, null)
    envelopeFrom       = optional(string, null)
    starttls           = optional(bool, null)
    ssl                = optional(bool, null)
    allowUtf8          = optional(bool, null)
  })
  default = null
}

variable "smtp_username" {
  description = "SMTP auth username (from the smtp credentials secret)."
  type        = string
  default     = null
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP auth password (from the smtp credentials secret)."
  type        = string
  default     = null
  sensitive   = true
}

# --- Realm Settings → Security Defenses ---
variable "security_defenses" {
  description = "Security Defenses tab: response headers + brute-force detection."
  type = object({
    headers = optional(object({
      xFrameOptions                   = optional(string, null)
      contentSecurityPolicy           = optional(string, null)
      contentSecurityPolicyReportOnly = optional(string, null)
      xContentTypeOptions             = optional(string, null)
      xRobotsTag                      = optional(string, null)
      xXssProtection                  = optional(string, null)
      strictTransportSecurity         = optional(string, null)
      referrerPolicy                  = optional(string, null)
    }), null)
    bruteForceDetection = optional(object({
      permanentLockout             = optional(bool, null)
      maxTemporaryLockouts         = optional(number, null)
      maxLoginFailures             = optional(number, null)
      waitIncrementSeconds         = optional(number, null)
      quickLoginCheckMilliSeconds  = optional(number, null)
      minimumQuickLoginWaitSeconds = optional(number, null)
      maxFailureWaitSeconds        = optional(number, null)
      failureResetTimeSeconds      = optional(number, null)
    }), null)
  })
  default = {}
}

# --- Realm Settings → Localization (internationalization) ---
variable "internationalization" {
  description = "Localization: supported locales + default locale."
  type = object({
    supportedLocales = list(string)
    defaultLocale    = string
  })
  default = null
}

# --- Authentication → Policies (password / OTP / WebAuthn) ---
variable "policies" {
  description = "Authentication → Policies: password policy + OTP + WebAuthn (+ passwordless)."
  type = object({
    passwordPolicy = optional(string, null)
    otpPolicy = optional(object({
      type            = optional(string, null) # totp | hotp
      algorithm       = optional(string, null) # HmacSHA1 | HmacSHA256 | HmacSHA512
      digits          = optional(number, null)
      initialCounter  = optional(number, null)
      lookAheadWindow = optional(number, null)
      period          = optional(number, null)
      codeReusable    = optional(bool, null)
    }), null)
    webAuthnPolicy = optional(object({
      relyingPartyEntityName          = optional(string, null)
      relyingPartyId                  = optional(string, null)
      signatureAlgorithms             = optional(list(string), null)
      attestationConveyancePreference = optional(string, null)
      authenticatorAttachment         = optional(string, null)
      discoverableCredential          = optional(string, null) # not specified | required | preferred | discouraged
      userVerificationRequirement     = optional(string, null)
      createTimeout                   = optional(number, null)
      avoidSameAuthenticatorRegister  = optional(bool, null)
      acceptableAaguids               = optional(list(string), null)
      extraOrigins                    = optional(list(string), null)
    }), null)
    webAuthnPasswordlessPolicy = optional(object({
      relyingPartyEntityName          = optional(string, null)
      relyingPartyId                  = optional(string, null)
      signatureAlgorithms             = optional(list(string), null)
      attestationConveyancePreference = optional(string, null)
      authenticatorAttachment         = optional(string, null)
      discoverableCredential          = optional(string, null) # not specified | required | preferred | discouraged
      userVerificationRequirement     = optional(string, null)
      createTimeout                   = optional(number, null)
      avoidSameAuthenticatorRegister  = optional(bool, null)
      acceptableAaguids               = optional(list(string), null)
      extraOrigins                    = optional(list(string), null)
      passwordlessPasskeysEnabled     = optional(bool, null)
    }), null)
  })
  default = {}
}
# NOTE: auth FLOW bindings (browser_flow, registration_flow, …) are intentionally
# OMITTED — use the dedicated keycloak_authentication_bindings sub-resource later.

# --- Realm Settings → General (top-level args) ---
# passwordPolicy lives in var.policies. General-tab UI fields without a keycloak_realm
# arg (Frontend URL, ACR-to-LoA, Unmanaged Attributes, SAML IdP signature algo) are set
# via `attributes` or out of scope.
variable "ssl_required" {
  description = "General: Require SSL — one of none | external | all."
  type        = string
  default     = null
}

variable "user_managed_access" {
  description = "General: allow users to manage their own resources."
  type        = bool
  default     = null
}

variable "organizations_enabled" {
  description = "General: enable organization support."
  type        = bool
  default     = null
}

variable "admin_permissions_enabled" {
  description = "General: Admin Permissions (fine-grained permissions v2). When true, openid-client `permissions` (v1) fail on this realm."
  type        = bool
  default     = null
}

variable "internal_id" {
  description = "Override the realm's internal ID (defaults to the realm name)."
  type        = string
  default     = null
}

variable "terraform_deletion_protection" {
  description = "When true, the realm cannot be deleted."
  type        = bool
  default     = null
}

variable "attributes" {
  description = "Custom realm attributes (also where General fields like frontendUrl live)."
  type        = map(string)
  default     = null
}

# --- Clients → Client registration (anonymous / authenticated access policies) ---
variable "client_registration" {
  description = "Clients → Client registration: access policies to create. Keycloak's built-in policies stay and every policy must pass."
  type = list(object({
    name       = string
    providerId = string                      # trusted-hosts | max-clients | consent-required | scope | allowed-client-templates | allowed-protocol-mappers | …
    subType    = string                      # anonymous | authenticated
    config     = optional(map(string), null) # multi-value keys are comma-separated, e.g. "trusted-hosts" = "localhost,127.0.0.1"
  }))
  default = []

  validation {
    condition     = alltrue([for p in var.client_registration : contains(["anonymous", "authenticated"], p.subType)])
    error_message = "client_registration subType must be anonymous or authenticated."
  }

  validation {
    condition     = length(distinct([for p in var.client_registration : "${p.subType}/${p.name}"])) == length(var.client_registration)
    error_message = "client_registration names must be unique per subType."
  }
}

# --- Client scopes → realm defaults (keycloak_realm_*_client_scopes) ---
variable "client_scopes" {
  description = "Client scopes assigned to every new client. Each list is authoritative when set; null leaves Keycloak's defaults."
  type = object({
    default  = optional(list(string), null)
    optional = optional(list(string), null)
  })
  default = {}
}
