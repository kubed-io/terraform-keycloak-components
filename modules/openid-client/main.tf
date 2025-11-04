locals {
  id = coalesce(var.id, terraform.workspace)
  name = coalesce(
    var.name,
    title(replace(local.id, "[^a-zA-Z0-9]", " "))
  )
}

data "keycloak_realm" "this" {
  realm = var.realm
}
