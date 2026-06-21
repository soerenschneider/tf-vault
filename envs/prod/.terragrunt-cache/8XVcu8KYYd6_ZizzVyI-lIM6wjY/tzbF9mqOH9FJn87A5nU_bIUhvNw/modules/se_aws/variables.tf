variable "mount_path" {
  type    = string
  default = "aws"
}

variable "identifier" {
  type    = string
  default = "default"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]{3,}$", var.identifier))
    error_message = "Invalid value for identifier. It should only contain letters (a-z, A-Z), underscores, and numbers with no spaces."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "roles" {
  type = list(object({
    name            = string
    credential_type = optional(string, "iam_user")
    role_arns       = optional(list(string))
    policy_arns     = optional(list(string))
    policy_document = optional(string)
  }))

  validation {
    condition     = length(var.roles) > 0
    error_message = "No roles provided"
  }
}

variable "aws_account_id" {
  type = string
}

variable "max_lease_ttl" {
  type    = number
  default = 7200

  validation {
    condition     = var.max_lease_ttl > 60
    error_message = "TTL should be at least 60"
  }
}

variable "default_lease_ttl" {
  type    = number
  default = 3600
}
