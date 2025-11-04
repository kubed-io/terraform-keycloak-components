variable "name" {
  description = "The name of the ldap server. Defaults to workspace name."
  type        = string
  default     = null
  nullable    = true
}

variable "realm" {
  description = "The realm in which to create the LDAP federation."
  type        = string
}

variable "enabled" {
  description = "Whether the LDAP federation is enabled."
  type        = bool
  default     = true
}

variable "vendor" {
  description = "LDAP vendor. I.e. rhds for Red Hat Directory Server, ad for Active Directory, other for other LDAP servers."
  type        = string
  default     = null
  nullable    = true
}

variable "connection_url" {
  description = "Connection URL to the LDAP server."
  type        = string
}

variable "connection_timeout" {
  description = "Connection timeout for LDAP connections."
  type        = string
  default     = null
  nullable    = true
}

variable "read_timeout" {
  description = "Read timeout for LDAP connections."
  type        = string
  default     = null
  nullable    = true
}

variable "bind_dn" {
  description = "DN of LDAP admin, which will be used by Keycloak to access LDAP server."
  type        = string
  default     = null
  nullable    = true
}

variable "bind_credential" {
  description = "(Optional) Password of LDAP admin. This attribute must be set if bind_dn is set."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
  # validate that if bind_dn is set, bind_credential must also be set
  validation {
    condition     = (var.bind_dn == null) || (var.bind_credential != null)
    error_message = "If 'bind_dn' is set, 'bind_credential' must also be set."
  }
}

variable "start_tls" {
  description = "(Optional) When true, Keycloak will encrypt the connection to LDAP using STARTTLS, which will disable connection pooling."
  type        = bool
  default     = null
  nullable    = true
}

variable "use_truststore_spi" {
  description = <<EOF
 (Optional) Can be one of ALWAYS, ONLY_FOR_LDAPS, or NEVER:
ALWAYS - Always use the truststore SPI for LDAP connections.
NEVER - Never use the truststore SPI for LDAP connections.
ONLY_FOR_LDAPS - Only use the truststore SPI if your LDAP connection uses the ldaps protocol.
EOF
  type        = string
  default     = null
  nullable    = true
}

variable "sync_settings" {
  description = "Settings for periodic sync of users from LDAP to Keycloak."
  type = object({
    importEnabled     = optional(bool)
    syncRegistrations = optional(bool)
    changeSyncPeriod  = optional(number)
    fullSyncPeriod    = optional(number)
    batchSize         = optional(number)
    pagination        = optional(bool)
  })
  default = {}
}

variable "mappers" {
  description = <<EOF
A set of mappers. Each has a type. Each type has a dedicated key with its specific configuration.
Supported types are:
- user
- userAttribute
- role
- group
- hardcodedRole
- hardcodedGroup
- hardcodedAttribute
- fullName
- custom
EOF
  type = set(object({
    type = string
    name = optional(string, null)
    user = optional(object({
      baseDn                      = string
      objectClasses               = list(string)
      uuidAttribute               = optional(string, "uid")
      rdnAttribute                = optional(string, "cn")
      usernameAttribute           = optional(string, "uid")
      searchFilter                = optional(string)
      searchScope                 = optional(string)
      trustEmail                  = optional(bool)
      mode                        = optional(string)
      validatePasswordPolicy      = optional(bool)
      usePasswordModifyExtendedOP = optional(bool)
    }))
    userAttribute = optional(object({
      ldapAttribute           = string
      userModelAttribute      = string
      alwaysReadValueFromLdap = optional(bool)
      readOnly                = optional(bool)
      isMandatoryInLdap       = optional(bool)
      attributeForceDefault   = optional(bool)
      attributeDefaultValue   = optional(string)
      isBinaryAttribute       = optional(bool)
    }))
    role = optional(object({
      baseDn                    = string
      nameAttribute             = string
      objectClasses             = list(string)
      membershipAttribute       = optional(string)
      membershipAttributeType   = optional(string)
      membershipUserAttribute   = optional(string)
      memberofAttribute         = optional(string)
      searchFilter              = optional(string)
      mode                      = optional(string)
      userRolesRetrieveStrategy = optional(string)
      useRealmRolesMapping      = optional(bool)
      clientId                  = optional(string)
    }))
    group = optional(object({
      baseDn                    = string
      nameAttribute             = string
      objectClasses             = list(string)
      preserveInheritance       = optional(bool)
      ignoreMissing             = optional(bool)
      membershipAttribute       = optional(string)
      membershipAttributeType   = optional(string)
      membershipUserAttribute   = optional(string)
      memberofAttribute         = optional(string)
      searchFilter              = optional(string)
      mode                      = optional(string)
      userRolesRetrieveStrategy = optional(string)
      mappedAttributes          = optional(list(string))
      dropNonExistingDuringSync = optional(bool)
      path                      = optional(string)
    }))
    hardcodedRole = optional(object({
      name = string
    }))
    hardcodedGroup = optional(object({
      name = string
    }))
    hardcodedAttribute = optional(object({
      name  = string
      value = string
    }))
    fullName = optional(object({
      attribute = string
      readOnly  = optional(bool)
      writeOnly = optional(bool)
    }))
    custom = optional(object({
      providerId   = string
      providerType = string
      config       = optional(map(string))
    }))
  }))
  default = []
  # make sure the correct mappers are configured
  validation {
    condition = alltrue([
      for mapper in var.mappers : (
        contains([
          "fullName",
          "userAttribute",
          "hardcodedAttribute",
          "role",
          "hardcodedRole",
          "group",
          "hardcodedGroup",
          "custom",
          "user"
        ], mapper.type)
        &&
        (
          mapper[mapper.type] != null
        )
      )
    ])
    error_message = "Each mapper object must have a non-null value for the key matching its 'type'."
  }
  # validate that there is one and only one 'user' mapper
  validation {
    condition = length([
      for mapper in var.mappers : mapper.name
      if mapper.type == "user"
    ]) == 1
    error_message = "There must be exactly one mapper of type 'user'."
  }
}
