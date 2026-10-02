terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.9.0"
    }
  }
}

provider "keycloak" {
  # client_id = "admin-cli"
  # url       = "https://auth.example.com"
  # username  = "admin"
  # password  = var.admin_password
}

# An `mcp` client scope: every client that requests it gets the MCP audience in its
# tokens, a groups claim, and the assigned roles.
module "mcp_scope" {
  source = "../../modules/openid-client-scope"

  realm                  = "kellyferrone"
  name                   = "mcp"
  description            = "Access to MCP servers behind the gateway."
  consent_screen_text    = "Use your MCP tools"
  include_in_token_scope = true

  protocol_mappers = [
    {
      name = "mcp-audience"
      type = "audience"
      audience = {
        includedCustom   = "https://mcp.kellyferrone.com/mcp"
        addToIdToken     = false
        addToAccessToken = true
      }
    },
    {
      name = "groups"
      type = "groupMembership"
      groupMembership = {
        claimName        = "groups"
        fullPath         = false
        addToAccessToken = true
      }
    },
  ]

  # Realm role, then a client role of the `grafana` client
  roles = [
    { name = "offline_access" },
    { name = "viewer", client = "grafana" },
  ]
}

output "mcp_scope" {
  value = module.mcp_scope
}
