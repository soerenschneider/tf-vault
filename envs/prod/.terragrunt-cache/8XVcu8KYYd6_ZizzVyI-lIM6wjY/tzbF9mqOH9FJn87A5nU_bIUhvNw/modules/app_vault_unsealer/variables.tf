variable "mount_path" {
  type    = string
  default = "transit/vault_unsealer"
}

variable "environments" {
  type    = list(string)
  default = ["prod"]
}

variable "default_lease_ttl" {
  type    = number
  default = 3600
}

variable "max_lease_ttl" {
  type    = number
  default = 7200
}
