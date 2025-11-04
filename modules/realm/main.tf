resource "keycloak_realm" "this" {
  realm             = coalesce(var.name, terraform.workspace)
  enabled           = var.enabled
  display_name      = title(coalesce(var.display_name, var.name))
  display_name_html = coalesce(var.display_name_html, var.display_name, var.name)
}
