variable "server_url" {
  type        = string
  description = "URL of this vault instance, e.g. https://my-vault:8200"
}

variable "cert_domain" {
  type = string
}

variable "root_mount_path" {
  type    = string
  default = "pki_root"
}

variable "root_mount_max_ttl" {
  type    = number
  default = 86400 * 365 * 3
}

variable "root_common_name" {
  type = string
}

variable "root_organization" {
  type = string
}

variable "root_key_type" {
  type    = string
  default = "rsa"
}

variable "root_key_bits" {
  type    = number
  default = 4096
  # TODO: enable validation
}

variable "root_ttl" {
  type    = number
  default = 315360000
}

variable "root_format" {
  type    = string
  default = "pem"
}

variable "root_private_key_format" {
  type    = string
  default = "der"
}

#-------------------------------------

variable "intermediate_mount_path" {
  type    = string
  default = "pki_intermediate"
}

variable "intermediate_mount_max_ttl" {
  type    = number
  default = 86400 * 365 * 3
}

variable "intermediate_ttl" {
  type    = number
  default = 86400 * 365 * 2
}

variable "intermediate_common_name" {
  type = string
}

variable "intermediate_organization" {
  type = string
}

variable "intermediate_ou" {
  type = string
}

variable "intermediate_key_bits" {
  type    = number
  default = 4096
  # TODO: enable validation
}

variable "intermediate_key_type" {
  type    = string
  default = "rsa"
}

variable "intermediate_format" {
  type    = string
  default = "pem"
}

variable "intermediate_private_key_format" {
  type    = string
  default = "der"
}

variable "backend_roles" {
  type = list(object({
    name               = string
    ttl                = optional(number)
    max_ttl            = optional(number),
    key_type           = optional(string)
    key_bits           = optional(number)
    allowed_domains    = list(string)
    allow_subdomains   = optional(bool)
    allow_bare_domains = optional(bool),
  }))
}
