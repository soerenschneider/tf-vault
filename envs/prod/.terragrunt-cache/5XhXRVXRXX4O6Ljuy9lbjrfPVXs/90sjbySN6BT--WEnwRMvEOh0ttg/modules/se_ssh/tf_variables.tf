variable "mount_path" {
  type = string
}

variable "identifier" {
  type        = string
  description = "Name for this secret engine, used to create policies"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{3,}$", var.identifier))
    error_message = "Invalid value for example_variable. It should be at least three characters long and only contain letters (a-z, A-Z), underscores, dashes, and numbers with no spaces."
  }
}

variable "sign_host_certificates" {
  type        = bool
  description = "Defines whether this secret engine only signs host certificates or whether it only signs client certificates"
}

variable "roles" {
  type = list(object({
    name                     = string
    key_type                 = optional(string, "ca")
    ttl                      = optional(number, 3600)
    max_ttl                  = optional(number, 7200)
    cidr_list                = optional(list(string), [])
    allowed_users            = optional(list(string), [])
    allowed_users_template   = optional(bool, false)
    allowed_domains          = optional(list(string), [])
    default_user             = optional(string)
    default_user_template    = optional(bool, false)
    algorithm_signer         = optional(string, "rsa-sha2-512")
    default_extensions       = optional(map(string), {})
    allowed_extensions       = optional(string)
    default_critical_options = optional(map(string), {})
    allowed_critical_options = optional(string)
  }))

  validation {
    condition     = alltrue([for r in var.roles : contains(["ca", "otp"], r.key_type)])
    error_message = "key_type must be \"ca\" or \"otp\"."
  }

  # Catch a template that silently never expands.
  validation {
    condition = alltrue([
      for r in var.roles :
      r.allowed_users_template ||
    !anytrue([for u in r.allowed_users : can(regex("\\{\\{", u))])
      ])
    error_message = "allowed_users contains a {{...}} template but allowed_users_template is false."
  }

  validation {
    condition = alltrue([
      for r in var.roles :
      r.default_user_template || r.default_user == null ||
    !can(regex("\\{\\{", r.default_user))
      ])
    error_message = "default_user contains a {{...}} template but default_user_template is false."
  }

  # A wildcard makes the template meaningless.
  validation {
    condition = alltrue([
      for r in var.roles :
      !r.allowed_users_template || !contains(r.allowed_users, "*")
      ])
    error_message = "allowed_users_template with \"*\" in allowed_users permits any principal."
  }
}
