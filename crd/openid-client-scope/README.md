# OpenidClientScope CRD

Crossplane CompositeResourceDefinition + Composition for the
[openid-client-scope](../../modules/openid-client-scope) module.

- **Group / version:** `keycloak.kubed.io/v1alpha1`
- **Kind:** `OpenidClientScope` (plural `openidclientscopes`)
- **Files:** [`definition.yaml`](definition.yaml) (OpenAPI v3 schema) ·
  [`composition.yaml`](composition.yaml) (field mappings → OpenTofu `Workspace`)

`spec` fields are camelCase mirrors of the module variables (`spec.consentScreenText` →
`consent_screen_text`); `protocolMappers` and `roles` pass through unchanged. The scope
name defaults to `metadata.name`; `spec.name` overrides it. For the full field reference,
see the **[openid-client-scope module README](../../modules/openid-client-scope)**.

## Status

| Field | Description |
| --- | --- |
| `status.clientScopeId` | The client scope's Keycloak ID. |

## Example

```yaml
apiVersion: keycloak.kubed.io/v1alpha1
kind: OpenidClientScope
metadata:
  name: mcp
spec:
  realm: kellyferrone
  description: Access to MCP servers behind the gateway.
  consentScreenText: Use your MCP tools
  protocolMappers:
  - name: mcp-audience
    type: audience
    audience:
      includedCustom: https://mcp.kellyferrone.com/mcp
      addToIdToken: false
  roles:
  - name: mcp-user
  - name: viewer
    client: grafana
```

---

[module](../../modules/openid-client-scope) · [↑ top-level README](../../README.md)
