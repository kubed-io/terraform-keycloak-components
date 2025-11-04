locals {
  name = coalesce(var.name, terraform.workspace)
  user_mapper = one([
    for mapper in var.mappers : mapper
    if mapper.type == "user"
  ]).user
}

data "keycloak_realm" "this" {
  realm = var.realm
}
