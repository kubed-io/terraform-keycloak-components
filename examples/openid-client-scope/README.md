# OpenID Client Scope Example

An `mcp` client scope: every client that requests it gets the MCP audience in its access
token, a `groups` claim, and the assigned roles. For the full field reference see the
[openid-client-scope module](../../modules/openid-client-scope); for the CRD itself see
[crd/openid-client-scope](../../crd/openid-client-scope).

## Terraform / OpenTofu

Calls the module directly ([main.tf](main.tf)). Configure the `keycloak` provider block to
point at your server, then:

```sh
tofu init
tofu apply
```

## Kubernetes

Applies an `OpenidClientScope` composite resource
([openid-client-scope.yaml](openid-client-scope.yaml)). Crossplane reconciles it into an
OpenTofu Workspace that calls the same module.

```sh
kubectl apply -k .
```

The scope name defaults to `metadata.name`; set `spec.name` to override it.

## Roles

`roles` are looked up by name when the plan runs, so they must already exist. Leave
`client` unset for a realm role, or give the owning client's `clientId` for a client role.

## Attaching the scope

A scope does nothing until a client gets it: list `mcp` in an `OpenidClient`'s
`scopes.default` / `scopes.optional`, or in a `Realm`'s `clientScopes` to hand it to every
new client.

---

[module](../../modules/openid-client-scope) · [CRD](../../crd/openid-client-scope) · [↑ top-level README](../../README.md)
