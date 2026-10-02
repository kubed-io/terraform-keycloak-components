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
