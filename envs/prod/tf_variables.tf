locals {
  server_cidrs = [
    "192.168.2.0/24",
    "192.168.65.0/24",
    "192.168.73.0/24"
  ]
}

variable "hosts_definition_file" {
  type    = string
  default = ""
}

variable "aws" {
  type = object({
    route53_hosted_zone = string
  })
}

variable "se_aws" {
  type = map(object({
    path       = string
    account_id = string
    region     = optional(string)
    roles = list(object({
      name            = string
      policy_arns     = optional(list(string))
      role_arns       = optional(list(string))
      credential_type = optional(string)
    }))
  }))

  default = {}
}

variable "audit_file" {
  type        = string
  description = "vault audit log file"
  default     = "/var/log/vault-audit.log"
}

variable "approles" {
  type = list(object({
    role_name             = string
    role_id               = optional(string)
    token_policies        = optional(list(string))
    token_max_ttl         = optional(number)
    token_ttl             = optional(number)
    token_bound_cidrs     = optional(list(string))
    secret_id_ttl         = optional(number)
    secret_id_num_uses    = optional(number)
    secret_id_bound_cidrs = optional(list(string))
    identity_metadata     = optional(map(string))
    groups                = optional(list(string))
  }))

  default = []
}

variable "identity_groups" {
  type = list(object({
    name     = string
    policies = optional(list(string))
  }))
  default = [
    { name = "fileserver", policies = ["occult"] }
  ]
}

variable "auth_k8s" {
  type = map(object({
    mount_path         = string
    host               = string
    ca_cert            = optional(string)
    ca_cert_file       = optional(string)
    token_reviewer_jwt = string
    roles = list(object({
      name                    = string
      bound_namespaces        = list(string)
      bound_svc_account_names = optional(list(string))
      token_ttl               = optional(number)
      token_policies          = list(string)
      audience                = optional(string)
      metadata                = optional(map(string))
      service_account_id      = optional(string)
    }))
  }))

  validation {
    condition = alltrue([
      for cluster in values(var.auth_k8s) :
      cluster.ca_cert == null && cluster.ca_cert_file != null || cluster.ca_cert != null && cluster.ca_cert_file == null
    ])
    error_message = "Supply either ca_cert or ca_cert_file for auth_k8s."
  }

  default = {}
}

variable "secret_engines_ssh" {
  type = map(object({
    mount_path             = string
    sign_host_certificates = bool
    roles = list(object({
      name               = string
      key_type           = optional(string)
      ttl                = optional(number)
      max_ttl            = optional(number)
      cidr_list          = optional(list(string))
      allowed_users      = optional(list(string))
      allowed_domains    = optional(list(string))
      default_user       = optional(string)
      algorithm_signer   = optional(string)
      default_extensions = optional(map(string))
      allowed_extensions = optional(string)
    }))
  }))

  default = {}
}

variable "secret_engines_k8s" {
  type = map(object({
    mount_path          = string
    name                = string
    host                = string
    ca_cert             = optional(string)
    ca_cert_file        = optional(string)
    service_account_jwt = string
    roles = list(object({
      name                 = string,
      allowed_namespaces   = list(string),
      token_default_ttl    = optional(number, 21600),
      token_max_ttl        = optional(number, 43200),
      kubernetes_role_name = optional(string),
      kubernetes_role_type = optional(string),
      extra_labels         = optional(map(string)),
      extra_annotations    = optional(map(string)),
    }))
  }))

  validation {
    condition = alltrue([
      for cluster in values(var.secret_engines_k8s) :
      cluster.ca_cert == null && cluster.ca_cert_file != null || cluster.ca_cert != null && cluster.ca_cert_file == null
    ])
    error_message = "Supply either ca_cert or ca_cert_file for secret_engines_k8s."
  }

  default = {}
}

variable "internal_pkis" {
  type = map(object({
    pki_cert_domain = string
    pki_backend_roles = list(object({
      name               = string
      allowed_domains    = list(string)
      ttl                = number
      max_ttl            = number
      key_bits           = number
      allow_bare_domains = bool
      allow_subdomains   = bool
    }))
    pki_root_common_name      = string
    pki_root_organization     = string
    pki_root_mount            = optional(string, null)
    pki_im_common_name        = string
    pki_im_organization       = string
    pki_im_ou                 = string
    pki_im_mount              = optional(string, null)
    pki_allowed_token_domains = optional(list(string), [])
  }))
  default = {}
}

variable "identities" {
  type = map(object({
    policies = optional(list(string), []),
    metadata = optional(map(string))
  }))
  default = {}
}

variable "users" {
  type = list(
    object(
      {
        name                   = string,
        token_policies         = optional(list(string), []),
        token_ttl              = optional(number, 28800),
        token_max_ttl          = optional(number, 86400),
        token_explicit_max_ttl = optional(number, 86400),
        token_num_uses         = optional(number, 0),
        token_bound_cidrs = optional(list(string), [
          "127.0.0.1/32",
          "172.16.0.0/12",
          "192.168.0.0/16"]
        )
      }
  ))
  default = []
}

variable "db_mariadb_dbs" {
  type = list(object({
    name           = string
    username       = string
    password       = string
    connection_url = string
    roles = list(object({
      name                = string
      creation_statements = list(string)
      max_ttl             = optional(number)
      default_ttl         = optional(number)
    }))
  }))

  default = []
}

variable "kv2_mount" {
  type    = string
  default = "secret"
}
