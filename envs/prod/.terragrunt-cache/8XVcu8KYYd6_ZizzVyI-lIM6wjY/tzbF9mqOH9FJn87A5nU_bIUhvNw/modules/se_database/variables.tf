variable "mount_path" {
  type    = string
  default = "dbs/mariadb"
}

variable "mariadb_dbs" {
  type = list(object({
    name           = string
    username       = string
    password       = string
    connection_url = string
    roles = list(object({
      name                = string
      creation_statements = list(string)
      max_ttl             = optional(number, 86400)
      default_ttl         = optional(number, 3600)
    }))
  }))

  default = []
}

variable "postgres_dbs" {
  type = list(object({
    name           = string
    username       = string
    password       = string
    connection_url = string
    roles = list(object({
      name                = string
      creation_statements = list(string)
      max_ttl             = optional(number, 86400)
      default_ttl         = optional(number, 3600)
    }))
  }))

  default = []
}