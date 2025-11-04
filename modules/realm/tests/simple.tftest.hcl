mock_provider "keycloak" {

}

run "simple_realm" {
  command = plan
  variables {
    name = "my-realm"
  }
}