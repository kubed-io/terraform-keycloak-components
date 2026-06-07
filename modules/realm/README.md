# Realm

Creates and manages a **Keycloak realm** — the logical boundary that owns a realm's users,
clients, roles, login behavior, token lifespans, email/SMTP, security defenses, and
authentication policies. Wraps the [`keycloak_realm`][provider] resource (provider
**5.8.0**) and exposes effectively its whole surface, **grouped by Keycloak admin-UI tab**:
the inputs mirror what you see in *Realm settings* + *Authentication → Policies*, so a
variable maps to the tab you'd edit by hand.

[provider]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/realm

## Shape: nested by UI tab → flat provider args

Each tab is **one object variable** whose keys are camelCase mirrors of the provider's
arguments (`var.tokens.ssoSessionIdleTimeout` → `sso_session_idle_timeout`). The module
flattens them onto the single `keycloak_realm` resource; the provider's single nested
blocks (`smtp_server`, `security_defenses`, `otp_policy`, …) are emitted **only when you
supply that group**, so an unset tab leaves Keycloak's own defaults untouched.

Every key is `optional(…, null)`, so the objects are always materialized with all keys
present-but-null — there is no "did the caller set this map key" guessing. Supplying
`var.smtp` / `var.internationalization` (which default to `null`) is what gates whether
those blocks appear at all.

## SMTP credentials are NOT inline

`var.smtp` carries the SMTP *server* settings (host, from, starttls, …) but **no
username/password**. Auth creds arrive via the separate sensitive vars
`smtp_username` / `smtp_password`, which feed the `smtp_server.auth` sub-block (only
emitted when `smtp_username` is set). In the cluster these come from a Secret wired into
`TF_VAR_smtp_username` / `TF_VAR_smtp_password` by the composition (the `Realm` CRD's
`spec.smtp.credentialsRef`) — the same secretRef→env pattern the LDAP federation uses for
its bind creds. The homelab reuses the LDAP service-account secret as the SMTP credential.

## Out of scope

**Authentication flow bindings** (`browser_flow`, `registration_flow`,
`reset_credentials_flow`, …) are intentionally omitted — those belong in the dedicated
`keycloak_authentication_bindings` sub-resource. `var.policies` leaves room for a future
`authentication` section without disturbing it.

## Variables

### General (top-level)

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | string | workspace name | The realm name (also its internal ID unless overridden). |
| `display_name` | string | `null` | Display name (title-cased from `name` if unset). |
| `display_name_html` | string | `null` | HTML display name (falls back to `display_name`/`name`). |
| `enabled` | bool | `true` | When false, users/clients can't access the realm. |
| `ssl_required` | string | `null` | Require SSL: `none` \| `external` \| `all`. |
| `user_managed_access` | bool | `null` | Allow users to manage their own resources. |
| `organizations_enabled` | bool | `null` | Enable organization support. |
| `admin_permissions_enabled` | bool | `null` | Fine-grained admin permissions (v2). |
| `internal_id` | string | `null` | Override the realm's internal ID. |
| `terraform_deletion_protection` | bool | `null` | When true, the realm can't be deleted. |
| `attributes` | map(string) | `null` | Custom realm attributes (also General fields w/o a dedicated arg, e.g. frontendUrl). |
| `default_default_client_scopes` | list(string) | `null` | Default *default* client scopes for new clients. |
| `default_optional_client_scopes` | list(string) | `null` | Default *optional* client scopes for new clients. |

### Grouped tabs (object vars)

| Variable | UI tab | Notable keys |
| --- | --- | --- |
| `themes` | Realm settings → Themes | `loginTheme`, `accountTheme`, `adminTheme`, `emailTheme` |
| `login` | Realm settings → Login | `registrationAllowed`, `resetPasswordAllowed`, `rememberMe`, `verifyEmail`, `loginWithEmailAllowed`, `duplicateEmailsAllowed`, `editUsernameAllowed`, `registrationEmailAsUsername` |
| `tokens` | Realm settings → Sessions + Tokens | session timeouts + token lifespans (Go-duration strings, e.g. `30m`), `revokeRefreshToken`, `refreshTokenMaxReuse`, `oauth2Device*` |
| `smtp` | Realm settings → Email | `host`*, `from`*, `port`, `fromDisplayName`, `replyTo`, `envelopeFrom`, `starttls`, `ssl`, `allowUtf8` (`null` ⇒ no SMTP block) |
| `security_defenses` | Realm settings → Security defenses | `headers{…8}`, `bruteForceDetection{…8}` (each sub-block independently gated) |
| `internationalization` | Realm settings → Localization | `supportedLocales`*, `defaultLocale`* (`null` ⇒ no block) |
| `policies` | Authentication → Policies | `passwordPolicy`, `otpPolicy{…}`, `webAuthnPolicy{…}`, `webAuthnPasswordlessPolicy{…}` |

\* required key when the group is supplied.

### SMTP auth (sensitive)

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `smtp_username` | string (sensitive) | `null` | SMTP auth username. Setting it emits the `smtp_server.auth` sub-block. |
| `smtp_password` | string (sensitive) | `null` | SMTP auth password. |

See [`variables.tf`](variables.tf) for the full key list of each object.

## Outputs

| Name | Description |
| --- | --- |
| `id` | the realm's internal ID |
| `realm` | the realm name |

(see [`outputs.tf`](outputs.tf))

## Example

```hcl
module "realm" {
  source = "git::https://github.com/kubed-io/terraform-keycloak-components.git//modules/realm?ref=main"

  name         = "kubed"
  display_name = "Kubed Realm"
  ssl_required = "external"

  login = {
    resetPasswordAllowed  = true
    rememberMe            = true
    verifyEmail           = true
    loginWithEmailAllowed = true
  }

  tokens = {
    ssoSessionIdleTimeout = "30m"
    accessTokenLifespan   = "5m"
  }

  smtp = {
    host     = "docker-mailserver.connect.svc.cluster.local"
    port     = 587
    from     = "noreply@kubed.io"
    starttls = true
  }
  smtp_username = "keycloak" # in-cluster: from the SMTP credentials Secret
  smtp_password = "changeme"

  policies = {
    passwordPolicy = "upperCase(1) and length(8) and notUsername"
    otpPolicy      = { type = "totp", algorithm = "HmacSHA1", digits = 6, period = 30 }
  }
}
```

See [`../../examples/realm`](../../examples/realm) for a full-featured example exercising
every tab, plus the matching `Realm` composite resource.

## References

- Provider — [`keycloak_realm`][provider]
