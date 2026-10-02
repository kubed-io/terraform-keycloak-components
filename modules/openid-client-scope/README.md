# OpenID Client Scope

Creates and manages a Keycloak **OpenID Connect client scope**: a named set of claims and
roles that clients request by name in `scope`. Wraps
[`keycloak_openid_client_scope`][scope] (provider **5.9.0**).

A client scope is owned by the API it describes, not by the clients that use it. Clients
attach it by name through openid-client's `scopes`; a realm hands it to every new client
through its `client_scopes`. This module only creates the scope.

[scope]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/openid_client_scope

## Variables

Every input mirrors the client scope's **Settings** tab, so they are flat.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `realm` | string | — (required) | Realm in which to create the scope. |
| `name` | string | workspace name | The scope name clients request and tokens carry in `scope`. |
| `description` | string | `null` | Description shown in the GUI. |
| `consent_screen_text` | string | `null` | Text on the consent screen; `null` ⇒ not shown there. |
| `include_in_token_scope` | bool | `null` (provider: `true`) | Add the name to the token's `scope` claim and introspection. |
| `include_in_openid_provider_metadata` | bool | `null` (provider: `true`) | List the scope in discovery's `scopes_supported`. |
| `gui_order` | number | `null` | Display order in the GUI and on the consent page. |
| `extra_config` | map(string) | `null` | Extra attributes passed through verbatim. |

## Outputs

| Name | Description |
| --- | --- |
| `name` | The client scope name. |
| `id` | The scope's Keycloak ID, used to attach protocol mappers. |

## Example

```hcl
module "mcp_scope" {
  source = "git::https://github.com/kubed-io/terraform-keycloak-components.git//modules/openid-client-scope?ref=main"

  realm                  = "kellyferrone"
  name                   = "mcp"
  description            = "Access to MCP servers behind the gateway."
  consent_screen_text    = "Use your MCP tools"
  include_in_token_scope = true
}
```
