terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.8.0"
    }
  }
}

provider "keycloak" {
  # client_id = "admin-cli"
  # url       = "https://auth.example.com"
  # username  = "admin"
  # password  = var.admin_password
}

# An LDAP user-federation for the `kubed` realm, exercising the required `user`
# mapper plus attribute, group, and role mappers, by calling the module directly.
# In the cluster the bind credential comes from a Secret wired by the composition;
# here it is passed inline (use a sensitive var in real config).
module "ldap" {
  source = "../../modules/ldap-federation"

  realm          = "kubed"
  name           = "company-ldap"
  connection_url = "ldap://lldap.connect.svc.cluster.local:3890"
  vendor         = "other"

  # Bind creds (in-cluster: sourced from a Secret via the CRD's bindSecretRef)
  bind_dn         = "uid=admin,ou=people,dc=kubed,dc=io"
  bind_credential = "changeme"

  # Drop Keycloak's read-only default mappers so only the declared ones exist.
  delete_default_mappers = true

  # --- Sync ---
  sync_settings = {
    importEnabled  = true
    fullSyncPeriod = 604800 # 1 week
    batchSize      = 1000
    pagination     = true
  }

  mappers = [
    # Exactly one `user` mapper is required — it feeds the federation itself.
    {
      name = "users"
      type = "user"
      user = {
        baseDn            = "ou=people,dc=kubed,dc=io"
        objectClasses     = ["inetOrgPerson", "person"]
        usernameAttribute = "uid"
        rdnAttribute      = "uid"
        uuidAttribute     = "uid"
        mode              = "READ_ONLY"
      }
    },

    # Map the LDAP `mail` attribute onto the Keycloak email field.
    {
      name = "email"
      type = "userAttribute"
      userAttribute = {
        ldapAttribute      = "mail"
        userModelAttribute = "email"
      }
    },

    # Combine first/last name from a single LDAP attribute.
    {
      name = "full-name"
      type = "fullName"
      fullName = {
        attribute = "cn"
        readOnly  = true
      }
    },

    # Import LDAP groups under ou=groups into Keycloak groups.
    {
      name = "groups"
      type = "group"
      group = {
        baseDn                  = "ou=groups,dc=kubed,dc=io"
        nameAttribute           = "cn"
        objectClasses           = ["groupOfNames"]
        membershipUserAttribute = "uid"
        membershipAttributeType = "DN"
        mode                    = "READ_ONLY"
      }
    },
  ]
}

output "ldap" {
  value = module.ldap
}
