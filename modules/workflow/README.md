# Workflow

Creates and manages a Keycloak **workflow**: when a realm event matches `on` and the user
satisfies `conditions`, Keycloak runs the steps in order, each after its own delay. Wraps
[`keycloak_workflow`][workflow] (provider **5.9.0**). Needs Keycloak 26.4+ with the
`workflows` feature, which is on by default from 26.8.

A realm holds any number of workflows, so each one is its own object instead of a realm
input. That way the app that needs a workflow can ship it next to its client.

[workflow]: https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/workflow

## Variables

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `realm` | string | — (required) | Realm the workflow runs in. |
| `name` | string | workspace name | Unique in the realm. |
| `on` | string | — (required) | Event expression that starts it. |
| `conditions` | string | `null` | Keycloak's `if`: an expression the user must satisfy. |
| `enabled` | bool | `null` (provider: `true`) | `false` starts nothing new and pauses running executions. |
| `concurrency` | string | `null` | `restart-in-progress` or `cancel-in-progress`. |
| `schedule` | object | `null` | `after`* (interval, e.g. `1d`), `batchSize`. One per workflow. |
| `steps` | list | — (required) | At least one `{ uses*, after, priority, config }`. |

\* required key when the object is supplied.

### Expressions (`on`, `conditions`)

Both take Keycloak's workflow expression language: functions combined with `and`, `or`,
`not` and parentheses.

| Field | Functions |
| --- | --- |
| `on` | `user-created`, `user-authenticated(client)`, `user-role-granted(role)`, `user-role-revoked(role)`, `user-group-membership-added(group)`, `user-group-membership-removed(group)`, `user-federated-identity-added(idp)`, `user-federated-identity-removed(idp)`, `client-created`, `client-authenticated` |
| `conditions` | `has-user-attribute(name=value)`, `has-role(role)`, `is-member-of(group)`, `has-identity-provider-link(idp)` |

A single event starts a workflow, so `user-created or user-authenticated` means either one.
With a `schedule`, each run starts the workflow for up to `batchSize` users that satisfy
`conditions`, or for every user when `conditions` is null.

### Steps

`uses` is the step type: `invite-user`, `notify-user`, `add-required-action`,
`remove-required-action`, `grant-role`, `revoke-role`, `join-group`, `leave-group`,
`set-user-attribute`, `remove-user-attribute`, `disable-user`, `delete-user`, `unlink-user`,
`restart`. `config` holds the step's own settings (Keycloak's `with`), all strings. Steps
refer to roles, groups and required actions by name; those must exist in the realm, and a
required action must be enabled there.

## Outputs

| Name | Description |
| --- | --- |
| `name` | The workflow name. |
| `id` | The workflow's Keycloak ID. |
| `errors` | Errors Keycloak recorded for the workflow. |

## Example

```hcl
module "invite_new_people" {
  source = "git::https://github.com/kubed-io/terraform-keycloak-components.git//modules/workflow?ref=main"

  realm = "example"
  name  = "invite-new-people"
  on    = "user-created"
  steps = [{ uses = "invite-user" }]
}
```

## References

- [Keycloak: Workflows](https://www.keycloak.org/docs/latest/server_admin/index.html#_understanding_workflow_definition_)
- [Provider: `keycloak_workflow`][workflow]
