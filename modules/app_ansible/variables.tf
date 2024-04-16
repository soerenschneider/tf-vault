variable "mount_path" {
  type    = string
  default = "transit_ansible"
}

variable "ttl_seconds" {
  type    = number
  default = 1800
}

variable "ttl_max_seconds" {
  type    = number
  default = 3600
}

variable "environments" {
  type    = set(string)
  default = ["prod"]
}

