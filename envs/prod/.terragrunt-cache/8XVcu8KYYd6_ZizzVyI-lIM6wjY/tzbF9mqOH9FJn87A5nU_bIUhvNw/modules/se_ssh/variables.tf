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
    name               = string
    key_type           = optional(string, "ca")
    ttl                = optional(number, 3600)
    max_ttl            = optional(number, 7200)
    cidr_list          = optional(list(string), [])
    allowed_users      = optional(list(string), [])
    allowed_domains    = optional(list(string), [])
    default_user       = optional(string)
    algorithm_signer   = optional(string, "rsa-sha2-512")
    default_extensions = optional(map(string), {})
    allowed_extensions = optional(string)
  }))

  #  validation {
  #    condition = var.sign_host_certificates == true ? true : alltrue([
  #      for role in var.roles :
  #         length(role.allowed_users) > 0 || length(role.default_user) > 0
  #      ])
  #    error_message = "Supply either ca_cert or ca_cert_file for secret_engines_k8s."
  #  }
}
