variable "name" {
  description = "The scope name clients request and tokens carry in `scope`. Defaults to the workspace name."
  type        = string
  default     = null
}

variable "realm" {
  description = "The realm in which to create the client scope."
  type        = string
}

variable "description" {
  description = "Description shown in the GUI."
  type        = string
  default     = null
}

variable "consent_screen_text" {
  description = "Text shown for this scope on the consent screen. When null, the scope is not shown there."
  type        = string
  default     = null
}

variable "include_in_token_scope" {
  description = "Add the scope name to the token's `scope` claim and the introspection response. Provider default: true."
  type        = bool
  default     = null
}

variable "include_in_openid_provider_metadata" {
  description = "List the scope in `scopes_supported` of the realm's OpenID discovery document. Provider default: true."
  type        = bool
  default     = null
}

variable "gui_order" {
  description = "Display order in the GUI, such as on the consent page."
  type        = number
  default     = null
}

variable "extra_config" {
  description = "Extra client scope attributes passed through verbatim."
  type        = map(string)
  default     = null
}

variable "protocol_mappers" {
  description = <<EOF
Protocol mappers on this client scope. Each has a `type` with a matching sub-object.
EOF
  default     = []
  type = set(object({
    name            = string
    type            = string
    audienceResolve = optional(object({}))
    audience = optional(object({
      includedClient          = optional(string)
      includedCustom          = optional(string)
      addToIdToken            = optional(bool)
      addToAccessToken        = optional(bool)
      addToTokenIntrospection = optional(bool)
    }))
    fullName = optional(object({
      addToIdToken     = optional(bool)
      addToAccessToken = optional(bool)
      addToUserinfo    = optional(bool)
    }))
    groupMembership = optional(object({
      claimName               = string
      fullPath                = optional(bool)
      addToIdToken            = optional(bool)
      addToAccessToken        = optional(bool)
      addToUserinfo           = optional(bool)
      addToTokenIntrospection = optional(bool) # unset follows addToAccessToken
    }))
    hardcodedClaim = optional(object({
      name             = string # claim_name
      value            = string
      valueType        = optional(string)
      addToIdToken     = optional(bool)
      addToAccessToken = optional(bool)
      addToUserinfo    = optional(bool)
    }))
    hardcodedRole = optional(object({
      name = string
    }))
    sub = optional(object({
      addToAccessToken        = optional(bool)
      addToTokenIntrospection = optional(bool)
    }))
    userAttribute = optional(object({
      name             = string # user_attribute
      claimName        = string
      valueType        = optional(string)
      aggregate        = optional(bool) # aggregate_attributes
      multivalued      = optional(bool)
      addToIdToken     = optional(bool)
      addToAccessToken = optional(bool)
      addToUserinfo    = optional(bool)
    }))
    userClientRole = optional(object({
      claimName               = string
      clientIdForRoleMappings = optional(string)
      prefix                  = optional(string) # client_role_prefix
      valueType               = optional(string)
      multivalued             = optional(bool)
      addToIdToken            = optional(bool)
      addToAccessToken        = optional(bool)
      addToUserinfo           = optional(bool)
    }))
    userProperty = optional(object({
      name             = string # user_property
      claimName        = string
      valueType        = optional(string)
      addToIdToken     = optional(bool)
      addToAccessToken = optional(bool)
      addToUserinfo    = optional(bool)
    }))
    userRealmRole = optional(object({
      claimName               = string
      realmRolePrefix         = optional(string)
      valueType               = optional(string)
      multivalued             = optional(bool)
      addToIdToken            = optional(bool)
      addToAccessToken        = optional(bool)
      addToUserinfo           = optional(bool)
      addToTokenIntrospection = optional(bool)
    }))
    userSessionNote = optional(object({
      name             = string # session_note
      claimName        = string
      valueType        = optional(string)
      addToIdToken     = optional(bool)
      addToAccessToken = optional(bool)
    }))
  }))

  validation {
    condition = alltrue([
      for m in var.protocol_mappers : contains(["audience", "audienceResolve", "fullName", "groupMembership", "hardcodedClaim", "hardcodedRole", "sub", "userAttribute", "userClientRole", "userProperty", "userRealmRole", "userSessionNote"], m.type) && m[m.type] != null
    ])
    error_message = "Each protocol mapper needs a known type and a non-null sub-object matching it."
  }
}

variable "roles" {
  description = "Client scope → Scope: roles assigned to this scope, by name. Set `client` (its clientId) for a client role; leave it null for a realm role."
  type = list(object({
    name   = string
    client = optional(string, null)
  }))
  default = []

  validation {
    condition = length(distinct([
      for r in var.roles :
      r.client == null ? r.name : "${r.client}/${r.name}"
    ])) == length(var.roles)
    error_message = "Each role must be listed once."
  }
}
