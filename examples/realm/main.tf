terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.8.0"
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

  name         = "kellyferrone"
  display_name = "Kelly Ferrone"

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
    from            = "noreply@mail.kellyferrone.com"
    fromDisplayName = "Kelly Ferrone"
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
      relyingPartyEntityName = "Kelly Ferrone"
      relyingPartyId         = "auth.kellyferrone.com"
      signatureAlgorithms    = ["ES256", "RS256"]
    }
  }
}

output "realm" {
  value = module.realm
}
