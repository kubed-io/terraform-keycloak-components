# OpenidClient CRD

Crossplane CompositeResourceDefinition + Composition for the
[openid-client](../../modules/openid-client) module.

- **Group / version:** `keycloak.kubed.io/v1alpha1`
- **Kind:** `OpenidClient` (plural `openidclients`)
- **Files:** [`definition.yaml`](definition.yaml) (OpenAPI v3 schema) ·
  [`composition.yaml`](composition.yaml) (field mappings → OpenTofu `Workspace`)

The Composition reconciles an OpenTofu `Workspace` that calls the openid-client module.
`spec` fields are camelCase mirrors of the module variables: top-level scalars are
transformed to the module's snake_case names (`spec.accessType` → `access_type`); nested
objects (`accessSettings`, `capabilities`, `protocolMappers`, …) pass through unchanged.

For the full field reference, validation rules, and enum values, see the
**[openid-client module README](../../modules/openid-client)** — it is the single source of
truth for every input.

## Status

| Field | Description |
| --- | --- |
| `status.clientSecret` | Generated client secret (sensitive). |
| `status.serviceAccountUserId` | Service-account user ID (when service accounts are enabled). |

## Example

```yaml
apiVersion: keycloak.kubed.io/v1alpha1
kind: OpenidClient
metadata:
  name: my-app
spec:
  realm: master
  accessType: CONFIDENTIAL
  accessSettings:
    redirectUris:
    - https://myapp.com/*
  capabilities:
    standardFlowEnabled: true
    pkceCodeChallengeMethod: S256
```

See [`../../examples/openid-client`](../../examples/openid-client) for more.

---

[module](../../modules/openid-client) · [examples](../../examples/openid-client) · [↑ top-level README](../../README.md)
