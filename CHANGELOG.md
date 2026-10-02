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
- Crossplane CRDs for `realm`, `openid-client` and `ldap-federation`, each driving the matching module.
