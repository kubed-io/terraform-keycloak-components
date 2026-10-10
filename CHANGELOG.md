# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
  These ARE the release notes. One short line per entry, written for a user of the
  modules. CI-only, test-only and docs-only PRs take the `no changelog` label.
-->

## [Unreleased]

### Added

- `realm` module: a Keycloak realm and its settings (login, tokens, SMTP, security, policies).
- `openid-client` module: an OpenID Connect client with its mappers, scopes, permissions and role mappers.
- `openid-client-scope` module: a realm client scope with its protocol mappers and roles.
- `ldap-federation` module: an LDAP user-federation provider and its mappers.
- Crossplane CRDs for `realm`, `openid-client`, `openid-client-scope` and `ldap-federation`, each driving the matching module.
- `realm` module: client policies, as `client_profiles` (executors) and `client_policies` (conditions → profiles).
- `workflow` module and `Workflow` CRD: a Keycloak workflow (event expression, conditions, schedule, steps).
- `openid-client` module: `authorization` takes the resource server's scopes, resources, policies (role, group, user, client, clientScope, time, regex, aggregate) and permissions, all by name.

### Fixed

- Group membership mappers keep their claim in token introspection: `addToTokenIntrospection` now follows `addToAccessToken` when unset, instead of the provider's `false`.
