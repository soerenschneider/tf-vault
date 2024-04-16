variable "mount_path" {
  type    = string
  default = "kubernetes"
}

variable "host" {
  type = string
  validation {
    condition     = can(regex("^https://.*", var.host))
    error_message = "The host URL must start with 'https://'"
  }
}

variable "ca_cert" {
  type = string
}

variable "token_reviewer_jwt" {
  type = string
}

variable "roles" {
  type = list(object({
    name                    = string
    bound_svc_account_names = optional(list(string), ["*"])
    bound_namespaces        = optional(list(string))
    token_ttl               = optional(number)
    token_policies          = list(string)
    audience                = optional(string, "")
  }))
}
