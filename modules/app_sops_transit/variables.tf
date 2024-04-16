variable "name" {
  type = string
}

variable "environments" {
  type = set(string)
}

variable "ttl_seconds" {
  type    = number
  default = 1800
}

variable "deletion_allowed" {
  type    = bool
  default = true
}

variable "ttl_max_seconds" {
  type    = number
  default = 3600
}
