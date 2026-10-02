terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.9.0"
    }
  }
}

provider "keycloak" {
  # client_id = "admin-cli"
  # url       = "https://auth.example.com"
  # username  = "admin"
  # password  = var.admin_password
}

# A full-featured realm exercising every tab the module exposes, by calling the
# realm module directly. SMTP auth creds come from the sensitive smtp_username /
# smtp_password vars (in the cluster these are wired from a Secret by the composition).
module "realm" {
  source = "../../modules/realm"

  name         = "example"
  display_name = "Example"

  # --- General ---
  ssl_required        = "external"
  user_managed_access = false

  # --- Themes ---
  themes = {
    loginTheme = "keycloak"
    emailTheme = "keycloak"
  }

  # --- Login ---
  login = {
    registrationAllowed   = false
    resetPasswordAllowed  = true
    rememberMe            = true
    verifyEmail           = true
    loginWithEmailAllowed = true
  }

  # --- Tokens / Sessions ---
  tokens = {
    ssoSessionIdleTimeout = "30m"
    ssoSessionMaxLifespan = "10h"
    accessTokenLifespan   = "5m"
  }

  # --- Email / SMTP (auth creds via the sensitive vars below) ---
  smtp = {
    host            = "docker-mailserver.connect.svc.cluster.local"
    port            = 587
    from            = "noreply@mail.example.com"
    fromDisplayName = "Example"
    starttls        = true
  }
  smtp_username = "keycloak" # in-cluster: from the SA/SMTP credentials Secret
  smtp_password = "changeme" # in-cluster: from the SA/SMTP credentials Secret

  # --- Security Defenses ---
  security_defenses = {
    bruteForceDetection = {
      maxLoginFailures = 30
      permanentLockout = false
    }
  }

  # --- Localization ---
  internationalization = {
    supportedLocales = ["en"]
    defaultLocale    = "en"
  }

  # --- Authentication → Policies ---
  policies = {
    passwordPolicy = "upperCase(1) and length(8) and notUsername"
    otpPolicy = {
      type      = "totp"
      algorithm = "HmacSHA1"
      digits    = 6
      period    = 30
    }
    webAuthnPolicy = {
      relyingPartyEntityName = "Example"
      relyingPartyId         = "auth.example.com"
      signatureAlgorithms    = ["ES256", "RS256"]
      discoverableCredential = "preferred"
    }
  }

  # --- Realm settings → Events ---
  events = {
    eventsListeners    = ["jboss-logging"]
    eventsEnabled      = true
    eventsExpiration   = 604800 # 1 week
    adminEventsEnabled = true
  }

  # --- Clients → Client registration (adds to Keycloak's built-in policies) ---
  client_registration = [
    {
      name       = "Local Trusted Hosts"
      providerId = "trusted-hosts"
      subType    = "anonymous"
      config = {
        "trusted-hosts"          = "localhost,127.0.0.1"
        "client-uris-must-match" = "true"
      }
    },
  ]

  # --- Client scopes → realm defaults (each list replaces Keycloak's) ---
  client_scopes = {
    default  = ["basic", "acr", "profile", "email", "roles", "web-origins"]
    optional = ["offline_access", "address", "phone"]
  }
}

output "realm" {
  value = module.realm
}
