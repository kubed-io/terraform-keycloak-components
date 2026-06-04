terraform {
  required_version = ">= 1.4.4"
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.5.0"
    }
    # Only used by LDAP-type role mappers: resolve an LDAP user-federation's GUID by
    # name via the Keycloak Admin REST `components` endpoint (the keycloak provider has
    # no federation/component data source). Inert unless a role mapper of type "ldap"
    # is declared.
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0.0"
    }
  }
}
