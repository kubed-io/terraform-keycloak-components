# OpenID Client CRD Example

This example demonstrates how to create an OpenID Connect client in Keycloak using the
Crossplane CRD. For the full field reference see the
[openid-client module](../../modules/openid-client); for the CRD itself see
[crd/openid-client](../../crd/openid-client).

## Files

| File | Shows |
| --- | --- |
| [example-client.yaml](example-client.yaml) | A web app: redirects, PKCE, token lifespans, scopes, protocol mappers |
| [billing-api.yaml](billing-api.yaml) | A resource server protecting URIs: group, role, time and aggregate policies; resource and scope permissions |
| [documents-api.yaml](documents-api.yaml) | A resource server by resource type: user, client, clientScope and NEGATIVE regex policies; AFFIRMATIVE decisions |
| [service-client.yaml](service-client.yaml) | A machine client: service account roles and an audience mapper |
| [main.tf](main.tf) | `billing-api` and the machine client through the module directly |

```sh
kubectl apply -k .        # the four OpenidClients, through Crossplane
tofu init && tofu apply   # main.tf, against the keycloak provider you configure there
```

The policies look up the users, groups, roles, clients and client scopes they name, so those
must exist in the realm first: the `/staff` group, the `billing-admin` realm role, users
`alice` and `bob`, the `n8n` client and the `documents` client scope.

## Simple Client Example

```yaml
apiVersion: keycloak.kubed.io/v1alpha1
kind: OpenidClient
metadata:
  name: my-web-app
spec:
  realm: master
  accessType: CONFIDENTIAL
  enabled: true
  description: "My Web Application"
  accessSettings:
    redirectUris:
      - "https://myapp.example.com/*"
      - "http://localhost:8080/*"
    webOrigins:
      - "+"
  capabilities:
    standardFlowEnabled: true
    directAccessGrantsEnabled: true
```

## Client with Protocol Mappers

```yaml
apiVersion: keycloak.kubed.io/v1alpha1
kind: OpenidClient
metadata:
  name: my-service-client
spec:
  realm: master
  accessType: CONFIDENTIAL
  enabled: true
  capabilities:
    serviceAccountsEnabled: true
  protocolMappers:
    - name: email-mapper
      type: userProperty
      userProperty:
        name: email
        claimName: email
        addToIdToken: true
        addToAccessToken: true
        addToUserinfo: true
    - name: groups-mapper
      type: groupMembership
      groupMembership:
        claimName: groups
        fullPath: false
        addToIdToken: true
        addToAccessToken: true
```

## Client with Authorization and Permissions

```yaml
apiVersion: keycloak.kubed.io/v1alpha1
kind: OpenidClient
metadata:
  name: my-protected-client
spec:
  realm: master
  accessType: CONFIDENTIAL
  enabled: true
  capabilities:
    serviceAccountsEnabled: true
  authorization:
    policyEnforcementMode: ENFORCING
    decisionStrategy: UNANIMOUS
  permissions:
    - scope: view
      policies:
        - "admin-policy-id"
      decisionStrategy: UNANIMOUS
      description: "Only admins can view this client"
    - scope: manage
      policies:
        - "super-admin-policy-id"
      decisionStrategy: AFFIRMATIVE
      description: "Only super admins can manage this client"
```

`permissions` above are admin permissions (who may view or manage this client), kept on the
realm's `realm-management` client. For permissions on the client's own resources, see the
next example.

## Client as a Resource Server

`authorization` lists the client's scopes, resources, policies and permissions, all by name.
See [billing-api.yaml](billing-api.yaml) for URI-based resources, and
[documents-api.yaml](documents-api.yaml) for permissions on a resource type and a deny rule.

## Client with Custom Scopes

```yaml
apiVersion: keycloak.kubed.io/v1alpha1
kind: OpenidClient
metadata:
  name: my-scoped-client
spec:
  realm: master
  accessType: PUBLIC
  enabled: true
  accessSettings:
    redirectUris:
      - "https://app.example.com/callback"
  scopes:
    default:
      - email
      - profile
      - roles
    optional:
      - address
      - phone
      - offline_access
```

## Full Featured Client

```yaml
apiVersion: keycloak.kubed.io/v1alpha1
kind: OpenidClient
metadata:
  name: full-featured-client
spec:
  realm: production
  name: "Full Featured Application"
  description: "A complete example with all features"
  enabled: true
  alwaysDisplayInConsole: true
  accessType: CONFIDENTIAL
  
  accessSettings:
    rootUrl: "https://app.example.com"
    adminUrl: "https://app.example.com/admin"
    baseUrl: "https://app.example.com"
    redirectUris:
      - "https://app.example.com/*"
      - "https://app.example.com/oauth/callback"
    webOrigins:
      - "https://app.example.com"
  
  capabilities:
    standardFlowEnabled: true
    implicitFlowEnabled: false
    directAccessGrantsEnabled: true
    serviceAccountsEnabled: true
    oauth2DeviceAuthorizationGrantEnabled: false
    pkceCodeChallengeMethod: S256
  
  login:
    consentRequired: true
    displayOnConsentScreen: true
    consentScreentText: "Allow access to your account"
  
  logout:
    frontChannelLogoutEnabled: true
    backchannelLogoutUrl: "https://app.example.com/logout"
    backchannelLogoutSessionRequired: true
  
  scopes:
    default:
      - email
      - profile
    optional:
      - offline_access
  
  protocolMappers:
    - name: audience-mapper
      type: audience
      audience:
        includedClient: "target-client"
        addToIdToken: true
        addToAccessToken: true
    
    - name: full-name
      type: fullName
      fullName:
        addToIdToken: true
        addToAccessToken: true
        addToUserinfo: true
    
    - name: email
      type: userProperty
      userProperty:
        name: email
        claimName: email
        addToIdToken: true
        addToAccessToken: true
        addToUserinfo: true
    
    - name: groups
      type: groupMembership
      groupMembership:
        claimName: groups
        fullPath: false
        addToIdToken: true
        addToAccessToken: true
  
  extraConfig:
    custom.setting: "value"
    another.setting: "another-value"
```

## Accessing the Client Secret

After the client is created, you can access the client secret from the status field:

```bash
kubectl get openidclient my-web-app -o jsonpath='{.status.clientSecret}'
```

For service account clients, you can also get the service account user ID:

```bash
kubectl get openidclient my-service-client -o jsonpath='{.status.serviceAccountUserId}'
```

---

[module](../../modules/openid-client) · [CRD](../../crd/openid-client) · [↑ top-level README](../../README.md)
