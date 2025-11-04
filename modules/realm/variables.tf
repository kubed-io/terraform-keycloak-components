variable "name" {
  description = "The name of the realm."
  type        = string
}

variable "display_name" {
  description = "The display name of the realm."
  type        = string
  default     = null
}

variable "display_name_html" {
  description = "The HTML display name of the realm."
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the realm is enabled."
  type        = bool
  default     = true
}


