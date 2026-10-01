terraform {
  required_version = ">= 1.4.4"
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.9.0"
    }
  }
}
