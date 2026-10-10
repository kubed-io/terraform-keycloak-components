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

# A resource server that protects URIs (same as billing-api.yaml). Staff may read invoices;
# editing needs a billing admin during business hours.
module "billing_api" {
  source = "../../modules/openid-client"

  realm        = "example"
  id           = "billing-api"
  description  = "Billing API, protected by Keycloak authorization"
  access_type  = "CONFIDENTIAL"
  capabilities = { standardFlowEnabled = false, serviceAccountsEnabled = true }

  authorization = {
    policyEnforcementMode = "ENFORCING"
    scopes                = [{ name = "view" }, { name = "edit", displayName = "Edit" }]
    resources = [
      { name = "invoices", uris = ["/invoices/*"], scopes = ["view", "edit"] },
      { name = "reports", uris = ["/reports/*"], scopes = ["view"] },
    ]
    policies = [
      {
        name  = "staff"
        type  = "group"
        group = { groups = [{ path = "/staff", extendChildren = true }] }
      },
      {
        name = "billing-admins"
        type = "role"
        role = { roles = [{ name = "billing-admin", required = true }] }
      },
      {
        name = "business-hours"
        type = "time"
        time = { hour = 9, hourEnd = 17 }
      },
      {
        name      = "admins-in-business-hours"
        type      = "aggregate"
        aggregate = { policies = ["billing-admins", "business-hours"] }
      },
    ]
    permissions = [
      { name = "read-billing", resources = ["invoices", "reports"], policies = ["staff"] },
      {
        name      = "edit-invoices"
        type      = "scope"
        resources = ["invoices"]
        scopes    = ["edit"]
        policies  = ["admins-in-business-hours"]
      },
    ]
  }
}

# A machine client (same as service-client.yaml): client credentials, roles on its service
# account, and the billing API in its tokens' audience.
module "invoice_sync" {
  source = "../../modules/openid-client"

  realm       = "example"
  id          = "invoice-sync"
  description = "Nightly job that syncs invoices"
  access_type = "CONFIDENTIAL"
  capabilities = {
    standardFlowEnabled       = false
    directAccessGrantsEnabled = false
    serviceAccountsEnabled    = true
  }

  service_account_roles = [
    { name = "offline_access" },
    { name = "billing-admin" },
  ]

  protocol_mappers = [{
    name = "billing-audience"
    type = "audience"
    audience = {
      includedClient   = "billing-api"
      addToIdToken     = false
      addToAccessToken = true
    }
  }]

  depends_on = [module.billing_api]
}

output "billing_api_resource_server_id" {
  value = module.billing_api.resource_server_id
}
