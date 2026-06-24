# LDAP Federation Example

An LDAP user-federation for the `kubed` realm, exercising the required `user` mapper plus
attribute, full-name, and group mappers. For the full field reference see the
[ldap-federation module](../../modules/ldap-federation); for the CRD itself see
[crd/ldap-federation](../../crd/ldap-federation).

## Terraform / OpenTofu

Calls the module directly ([main.tf](main.tf)). Configure the `keycloak` provider block to
point at your server, then:

```sh
tofu init
tofu apply
```

The bind credential is passed inline here for clarity — use a sensitive variable in real
config.

## Kubernetes

Applies an `LdapFederation` composite resource ([ldapfederation.yaml](ldapfederation.yaml)).
Crossplane reconciles it into an OpenTofu Workspace that calls the same module.

```sh
kubectl apply -k .
```

### Bind credentials

The federation's bind DN and credential are **not** in the spec. `spec.bindSecretRef` points
at a Secret whose keys the composition wires into `TF_VAR_bind_dn` / `TF_VAR_bind_credential`:

| Secret key | Maps to |
| --- | --- |
| `dn` | bind DN (LDAP admin) |
| `password` | bind credential |

This example references `keycloak-ldap-creds` in the `auth` namespace; create it (e.g. via
External Secrets Operator) before applying:

```sh
kubectl -n auth create secret generic keycloak-ldap-creds \
  --from-literal=dn='uid=admin,ou=people,dc=kubed,dc=io' \
  --from-literal=password='changeme'
```

## Mappers

| Mapper | Type | Purpose |
| --- | --- | --- |
| `users` | `user` (required, ×1) | User search base + object classes that feed the federation itself. |
| `email` | `userAttribute` | Maps the LDAP `mail` attribute to the Keycloak email field. |
| `full-name` | `fullName` | Splits a single `cn` attribute into first/last name. |
| `groups` | `group` | Imports LDAP groups under `ou=groups` into Keycloak groups. |

`role`, `hardcodedRole`, `hardcodedGroup`, `hardcodedAttribute`, and `custom` mappers are
also supported — see the [module README](../../modules/ldap-federation) for every type.

---

[module](../../modules/ldap-federation) · [CRD](../../crd/ldap-federation) · [↑ top-level README](../../README.md)
