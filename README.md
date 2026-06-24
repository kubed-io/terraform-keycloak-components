# Keycloak Components

Reusable [Terraform]/[OpenTofu] modules that manage [Keycloak] objects through the
[`keycloak/keycloak`][provider] provider (pinned **5.8.0**), each paired with a
[Crossplane] CRD so the same module can be driven two ways:

- **Terraform / OpenTofu** — call a module under [`modules/`](modules) directly:
  `source = "git::https://github.com/kubed-io/terraform-keycloak-components.git//modules/<name>?ref=main"`.
- **Kubernetes (Crossplane)** — apply the matching CRD from [`crd/`](crd); its Composition
  reconciles an OpenTofu `Workspace` that calls the very same module. See [CRDs](#crds).

## Modules

| Module | CRD kind | Manages |
| --- | --- | --- |
| [realm](#realm) | `Realm` | A Keycloak realm and its settings (login, tokens, SMTP, security, policies). |
| [openid-client](#openid-client) | `OpenidClient` | An OpenID Connect client, its mappers, scopes, permissions, and role mappers. |
| [ldap-federation](#ldap-federation) | `LdapFederation` | An LDAP user-federation provider and its attribute/role/group mappers. |

All CRDs live in the `keycloak.kubed.io/v1alpha1` group.

### realm

Creates and manages a **realm** — the boundary that owns its users, clients, roles, login
behavior, token lifespans, email/SMTP, security defenses, and authentication policies.
Inputs mirror the Keycloak admin-UI tabs, so a variable maps to the tab you'd edit by hand.

[module](modules/realm) · [CRD](crd/realm) · [example](examples/realm)

### openid-client

Creates and manages an **OpenID Connect client** and everything attached to it: access
settings, OAuth2 capabilities, login/logout, fine-grained authorization & permissions,
client scopes, the full set of protocol mappers, and client-scoped role mappers.

[module](modules/openid-client) · [CRD](crd/openid-client) · [example](examples/openid-client)

### ldap-federation

Creates and manages an **LDAP user-federation** provider for a realm, plus its mappers
(user, attribute, role, group, full-name, hardcoded, and custom).

[module](modules/ldap-federation) · [CRD](crd/ldap-federation) · [example](examples/ldap-federation)

## CRDs

Each module ships a Crossplane **CompositeResourceDefinition** + **Composition** under
[`crd/<name>/`](crd) (group `keycloak.kubed.io`, version `v1alpha1`). The Composition
reconciles an [OpenTofu] `Workspace` (`opentofu.upbound.io`) whose `module` points back at
this repo's matching module; a `patch-and-transform` pipeline maps the CR's `spec` onto the
module's `varmap`, so the CR fields are camelCase mirrors of the module variables.

Sensitive inputs never appear in the spec: the Composition wires a referenced Secret into
the workspace's `TF_VAR_*` env (e.g. the realm's SMTP creds, the federation's bind
credential).

Deploy all three with kustomize:

```sh
kubectl apply -k crd
```

## References

- [Terraform Provider][provider]
- [OpenTofu Provider](https://search.opentofu.org/provider/keycloak/keycloak/latest)
- [Crossplane] · [OpenTofu provider for Crossplane](https://github.com/upbound/provider-opentofu)

[Terraform]: https://www.terraform.io
[OpenTofu]: https://opentofu.org
[Keycloak]: https://www.keycloak.org
[Crossplane]: https://www.crossplane.io
[provider]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs
