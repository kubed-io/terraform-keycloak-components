# Workflow Example

Two workflows: one invites every person an admin creates, the other nudges people who stop
logging in and then disables them. For the full field reference see the
[workflow module](../../modules/workflow); for the CRD itself see
[crd/workflow](../../crd/workflow).

## Terraform / OpenTofu

Calls the module directly ([main.tf](main.tf)). Configure the `keycloak` provider block to
point at your server, then:

```sh
tofu init
tofu apply
```

## Kubernetes

Applies two `Workflow` composite resources ([workflow.yaml](workflow.yaml)). Crossplane
reconciles each into an OpenTofu Workspace that calls the same module.

```sh
kubectl apply -k .
```

The workflow name defaults to `metadata.name`; set `spec.name` to override it. Quote the
`'on'` key: unquoted, YAML 1.1 reads it as a boolean.

---

[module](../../modules/workflow) · [CRD](../../crd/workflow) · [↑ top-level README](../../README.md)
