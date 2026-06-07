# Realm Example

A full-featured Keycloak realm exercising every tab the [`realm`](../../modules/realm)
module exposes — General, Themes, Login, Tokens/Sessions, Email/SMTP, Security Defenses,
Localization, and Authentication → Policies (password / OTP / WebAuthn).

```sh
tofu init
tofu apply
```

Configure the `keycloak` provider block in [main.tf](main.tf) to point at your server
before applying. SMTP auth credentials are passed as the sensitive `smtp_username` /
`smtp_password` variables.

## Kubernetes

Applies a `Realm` composite resource ([realm.yaml](realm.yaml)). Crossplane reconciles it
into an OpenTofu Workspace that calls the same module.

```sh
kubectl apply -k .
```

The realm's SMTP block sources its auth credentials from a Secret via
`spec.smtp.credentialsRef` (keys `username` / `password`) — in the homelab this is the
LDAP service-account secret, which doubles as the SMTP credential. The composition wires
those into `TF_VAR_smtp_username` / `TF_VAR_smtp_password` so they never appear in the
spec. Omit `spec.smtp` entirely and no SMTP/env is configured.

## Tabs → fields

| UI tab / section            | spec field              |
| --------------------------- | ----------------------- |
| General                     | top-level (`sslRequired`, `userManagedAccess`, `attributes`, …) |
| Realm settings → Themes     | `themes`                |
| Realm settings → Login      | `login`                 |
| Realm settings → Sessions/Tokens | `tokens`           |
| Realm settings → Email      | `smtp` (+ `credentialsRef`) |
| Realm settings → Security defenses | `securityDefenses` |
| Realm settings → Localization | `internationalization` |
| Authentication → Policies   | `policies` (`passwordPolicy`, `otpPolicy`, `webAuthnPolicy`, `webAuthnPasswordlessPolicy`) |

Authentication **flow bindings** (`browser_flow`, etc.) are intentionally out of scope —
use the dedicated `keycloak_authentication_bindings` sub-resource for those.
