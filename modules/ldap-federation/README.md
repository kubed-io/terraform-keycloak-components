# LDAP Federation

Creates and manages a Keycloak **LDAP user-federation** provider for a realm, plus the
mappers that bind LDAP entries to Keycloak users, attributes, roles, and groups. Wraps
[`keycloak_ldap_user_federation`][fed] (provider **5.8.0**) and its mapper resources
([`_ldap_user_attribute_mapper`][attr], [`_ldap_role_mapper`][role],
[`_ldap_group_mapper`][group], [`_ldap_full_name_mapper`][fullname],
[`_ldap_hardcoded_*`][hardcoded], [`_ldap_custom_mapper`][custom]).

[fed]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/ldap_user_federation

## Shape: one `mappers` set, with a required `user` mapper

The federation's core connection/sync settings are top-level variables. Everything that
binds LDAP data into Keycloak is a single typed `set`, `var.mappers`, where each element
carries a `type` and a matching sub-object — the same discriminated-union pattern the
OpenID client uses.

The **`user` mapper is special and required** (exactly one): its sub-object supplies the
user search base (`baseDn`), object classes, and the RDN/UUID/username attributes that the
federation resource itself needs. The module reads that single `user` mapper to populate
`keycloak_ldap_user_federation`; all other mapper types become their own mapper resources.

## `delete_default_mappers`

Keycloak auto-creates a set of **read-only** default mappers for every new LDAP federation.
On a *writable* federation those defaults shadow any custom writable mapper for the same
attribute (the read-only one wins and blocks the write). Set
`delete_default_mappers = true` so only your declared mappers exist.

## Bind credentials

`bind_dn` + `bind_credential` (sensitive) authenticate Keycloak to the LDAP server. The
module validates that `bind_credential` is set whenever `bind_dn` is. In the cluster the
CRD's Composition wires these from a Secret into `TF_VAR_bind_credential` rather than the
spec — the same secretRef→env pattern the realm uses for SMTP auth.

## Variables

### Connection (top-level)

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `realm` | string | — (required) | Realm in which to create the federation. |
| `connection_url` | string | — (required) | LDAP server URL (e.g. `ldap://…` / `ldaps://…`). |
| `name` | string | workspace name | Federation display name. |
| `enabled` | bool | `true` | Whether the federation is enabled. |
| `vendor` | string | `null` | `rhds`, `ad`, or `other`. |
| `bind_dn` | string | `null` | DN Keycloak binds as to read LDAP. |
| `bind_credential` | string (sensitive) | `null` | Password for `bind_dn` (required if `bind_dn` set). |
| `start_tls` | bool | `null` | Encrypt with STARTTLS (disables connection pooling). |
| `use_truststore_spi` | string | `null` | `ALWAYS` \| `ONLY_FOR_LDAPS` \| `NEVER`. |
| `connection_timeout` | string | `null` | LDAP connection timeout. |
| `read_timeout` | string | `null` | LDAP read timeout. |
| `delete_default_mappers` | bool | `false` | Delete Keycloak's read-only default mappers (see above). |

### Sync (`sync_settings`)

Object with `importEnabled`, `syncRegistrations`, `changeSyncPeriod`, `fullSyncPeriod`,
`batchSize`, `pagination` — all optional; controls periodic LDAP→Keycloak sync.

### Mappers (`mappers`)

A `set` of objects, each with a `name`, a `type`, and a sub-object named after the `type`.
Exactly one element must be of type `user`. Supported types:

| Type | Resource | Purpose |
| --- | --- | --- |
| `user` (×1, required) | (feeds the federation) | User search base, object classes, RDN/UUID/username attrs, edit mode. |
| `userAttribute` | [`_ldap_user_attribute_mapper`][attr] | Map an LDAP attribute to a Keycloak user-model attribute. |
| `role` | [`_ldap_role_mapper`][role] | Map LDAP entries to realm or client roles. |
| `group` | [`_ldap_group_mapper`][group] | Map an LDAP subtree to Keycloak groups. |
| `fullName` | [`_ldap_full_name_mapper`][fullname] | Map a single full-name attribute to first/last name. |
| `hardcodedRole` | [`_ldap_hardcoded_*`][hardcoded] | Grant a fixed role to all federated users. |
| `hardcodedGroup` | [`_ldap_hardcoded_*`][hardcoded] | Add all federated users to a fixed group. |
| `hardcodedAttribute` | [`_ldap_hardcoded_*`][hardcoded] | Set a fixed attribute on all federated users. |
| `custom` | [`_ldap_custom_mapper`][custom] | Any mapper by `providerId`/`providerType` + `config`. |

See [`variables.tf`](variables.tf) for each sub-object's full key list.

## Outputs

| Name | Description |
| --- | --- |
| `id` | The federation's GUID — needed as `ldap_user_federation_id` by any role mapper declared outside this module (e.g. an `openid-client` `ldap` role mapper). |
| `realm` | The realm this federation lives in. |
| `name` | The federation's display name. |

(see [`outputs.tf`](outputs.tf))

## Example

```hcl
module "ldap" {
  source = "git::https://github.com/kubed-io/terraform-keycloak-components.git//modules/ldap-federation?ref=main"

  realm                  = "kubed"
  name                   = "company-ldap"
  connection_url         = "ldap://lldap.connect.svc.cluster.local:3890"
  bind_dn                = "uid=admin,ou=people,dc=kubed,dc=io"
  bind_credential        = "changeme" # in-cluster: from a Secret via the CRD
  delete_default_mappers = true

  mappers = [
    {
      name = "users"
      type = "user"
      user = {
        baseDn        = "ou=people,dc=kubed,dc=io"
        objectClasses = ["inetOrgPerson", "person"]
        mode          = "READ_ONLY"
      }
    },
    {
      name = "email"
      type = "userAttribute"
      userAttribute = {
        ldapAttribute      = "mail"
        userModelAttribute = "email"
      }
    },
    {
      name = "groups"
      type = "group"
      group = {
        baseDn                  = "ou=groups,dc=kubed,dc=io"
        nameAttribute           = "cn"
        objectClasses           = ["groupOfNames"]
        membershipUserAttribute = "uid"
      }
    },
  ]
}
```

See [`../../examples/ldap-federation`](../../examples/ldap-federation) for the full HCL +
`LdapFederation` composite-resource example, including the bind-credential Secret.

## References

- Provider — [`keycloak_ldap_user_federation`][fed], [`_ldap_user_attribute_mapper`][attr],
  [`_ldap_role_mapper`][role], [`_ldap_group_mapper`][group],
  [`_ldap_full_name_mapper`][fullname], [`_ldap_custom_mapper`][custom]
- This repo — [CRD](../../crd/ldap-federation) · [example](../../examples/ldap-federation) · [↑ top-level README](../../README.md)

[attr]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/ldap_user_attribute_mapper
[role]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/ldap_role_mapper
[group]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/ldap_group_mapper
[fullname]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/ldap_full_name_mapper
[hardcoded]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/ldap_hardcoded_role_mapper
[custom]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/ldap_custom_mapper
