variable "mount_path" {
  type    = string
  default = "kubernetes"
}

variable "identifier" {
  type        = string
  description = "A short name for the cluster. Used to create policies."

  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\.-]{3,}$", var.identifier))
    error_message = "Invalid value for identifier. It should be at least three characters long and only contain letters (a-z, A-Z), underscores, dashes, and numbers with no spaces."
  }
}

variable "default_ttl_lease_seconds" {
  type    = number
  default = 43200
}

variable "max_ttl_lease_seconds" {
  type    = number
  default = 86400
}

variable "host" {
  type = string
}

variable "ca_cert" {
  type = string
}

variable "service_account_jwt" {
  type = string
}

variable "roles" {
  type = list(
    object(
      {
        name                 = string,
        allowed_namespaces   = list(string),
        token_default_ttl    = optional(number, 21600),
        token_max_ttl        = optional(number, 43200),
        kubernetes_role_name = optional(string),
        kubernetes_role_type = optional(string),
        service_account_name = optional(string),
        extra_labels         = optional(map(string)),
        extra_annotations    = optional(map(string)),
      }
  ))
}
