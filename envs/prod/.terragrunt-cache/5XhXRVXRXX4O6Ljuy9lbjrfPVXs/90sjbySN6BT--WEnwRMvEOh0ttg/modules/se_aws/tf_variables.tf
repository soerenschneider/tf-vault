variable "identifier" {
  description = <<-EOT
    Unique short name for this module instance. Everything this module owns in AWS
    and Vault is namespaced by it, so it MUST be unique per AWS account. Changing it
    is destructive: see the migration notes in the README.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,30}$", var.identifier))
    error_message = "identifier must be 1-31 characters of lowercase alphanumerics and hyphens, starting with an alphanumeric."
  }
}

variable "region" {
  description = "AWS region the secrets engine issues credentials in."
  type        = string
  default     = null
}

variable "mount_path" {
  description = "Vault mount path for the engine. Defaults to aws/<identifier>."
  type        = string
  default     = null

  validation {
    condition     = var.mount_path == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9_/-]*[a-zA-Z0-9]$", var.mount_path))
    error_message = "mount_path must not begin or end with a slash."
  }
}

variable "description" {
  description = "Description applied to the Vault mount."
  type        = string
  default     = null
}

variable "default_lease_ttl" {
  description = "Default lease TTL for issued credentials, in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.default_lease_ttl > 0
    error_message = "default_lease_ttl must be greater than zero."
  }
}

variable "max_lease_ttl" {
  description = "Maximum lease TTL for issued credentials, in seconds."
  type        = number
  default     = 86400

  validation {
    condition     = var.max_lease_ttl > 0
    error_message = "max_lease_ttl must be greater than zero."
  }
}

variable "roles" {
  description = <<-EOT
    Roles exposed by the secrets engine.

    credential_type defaults to iam_user. Note that federation_token and
    session_token credentials cannot call the IAM API at all, so any role whose
    purpose includes IAM access (e.g. IAMReadOnlyAccess) must use iam_user.

    Set permissions_boundary_arn to "" to opt a specific role out of the boundary
    this module creates; leave it null to use the module boundary.
  EOT

  type = list(object({
    name                     = string
    credential_type          = optional(string, "iam_user")
    policy_arns              = optional(list(string))
    policy_document          = optional(string)
    role_arns                = optional(list(string))
    iam_groups               = optional(list(string))
    iam_tags                 = optional(map(string))
    permissions_boundary_arn = optional(string)
    default_sts_ttl          = optional(number)
    max_sts_ttl              = optional(number)
    vault_policy_name        = optional(string)
  }))

  default = []

  validation {
    condition     = length(distinct([for r in var.roles : r.name])) == length(var.roles)
    error_message = "Role names must be unique."
  }

  validation {
    condition = alltrue([
      for r in var.roles : contains(["iam_user", "assumed_role", "federation_token", "session_token"], r.credential_type)
    ])
    error_message = "credential_type must be one of: iam_user, assumed_role, federation_token, session_token."
  }

  validation {
    condition = alltrue([
      for r in var.roles : r.credential_type != "assumed_role" || length(coalesce(r.role_arns, [])) > 0
    ])
    error_message = "Roles with credential_type = assumed_role require role_arns."
  }

  validation {
    condition = alltrue([
      for r in var.roles : r.credential_type != "iam_user" || anytrue([
        length(coalesce(r.policy_arns, [])) > 0,
        r.policy_document != null,
        length(coalesce(r.iam_groups, [])) > 0,
      ])
    ])
    error_message = "Roles with credential_type = iam_user require at least one of policy_arns, policy_document, or iam_groups."
  }

  validation {
    condition = alltrue([
      for r in var.roles : r.credential_type == "iam_user" || (
        r.iam_groups == null && r.iam_tags == null && r.permissions_boundary_arn == null
      )
    ])
    error_message = "iam_groups, iam_tags and permissions_boundary_arn are only valid when credential_type = iam_user."
  }
}

variable "create_iam_user" {
  description = <<-EOT
    Create a dedicated IAM user and static access key for the engine.

    Set to false if Vault already has AWS credentials from its environment
    (EC2 instance profile, EKS IRSA, or plugin workload identity federation). In
    that case attach the policy exported as engine_policy_arn to Vault's own role
    and the engine will use ambient credentials.
  EOT
  type        = bool
  default     = true
}

variable "iam_user_force_destroy" {
  description = "Allow destroying the engine IAM user even if it has keys Terraform does not manage (e.g. after a Vault root rotation)."
  type        = bool
  default     = false
}

variable "allow_root_rotation" {
  description = <<-EOT
    Grant the engine permission to rotate its own access key
    (sys/mounts/<path>/config/rotate-root). Read the README first: this puts the
    key out of sync with Terraform state.
  EOT
  type        = bool
  default     = false
}

variable "create_permissions_boundary" {
  description = "Create a permissions boundary and attach it to dynamically created IAM users."
  type        = bool
  default     = true
}

variable "boundary_restricts_principal_creation" {
  description = <<-EOT
    Make the permissions boundary deny creating IAM users or roles that do not
    carry the same boundary. Without this, a credential holding IAMFullAccess can
    step outside the boundary in one call. Set to false if your admin role
    legitimately needs to create unbounded principals.
  EOT
  type        = bool
  default     = true
}

variable "manage_vault_policies" {
  description = "Create a Vault ACL policy per role."
  type        = bool
  default     = true
}

variable "vault_policy_name_prefix" {
  description = "Prefix for generated Vault policy names. Defaults to aws_<identifier>_ to match the historical naming."
  type        = string
  default     = null
}

variable "username_template" {
  description = "Optional Vault username template for dynamically created IAM users. Leave null for the engine default."
  type        = string
  default     = null
}

variable "dynamic_user_tags" {
  description = "Tags applied to every dynamically created IAM user. Requires iam:TagUser, which this module grants."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the AWS resources this module manages directly."
  type        = map(string)
  default     = {}
}
