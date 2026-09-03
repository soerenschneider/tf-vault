variable "mount_path" {
  type    = string
  default = "kubernetes"

  validation {
    condition     = length(var.mount_path) > 0
    error_message = "The mount path  must not be empty."
  }
}

variable "name" {
  type = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The cluster name  must not be empty."
  }
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

  validation {
    condition     = length(var.ca_cert) > 0
    error_message = "Kubernetes ca_cert must not be empty."
  }
}

variable "token_reviewer_jwt" {
  type = string

  validation {
    condition     = length(var.token_reviewer_jwt) > 0
    error_message = "Kubernetes token reviewer JWT must not be empty."
  }
}

variable "roles" {
  type = list(object({
    name                    = string
    bound_svc_account_names = optional(list(string), ["*"])
    bound_namespaces        = optional(list(string))
    token_ttl               = optional(number)
    token_policies          = list(string)
    audience                = optional(string, "")
    metadata                = optional(map(string))
    service_account_id      = optional(string, "")
  }))
}
