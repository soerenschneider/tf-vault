variable "environment" {
  type = string
}

variable "aws_path" {
  type = string
}

variable "kv2_base_path" {
  type    = string
}

variable "acmevault_zones" {
  description = <<-EOD
    Route 53 zones acmevault may write ACME challenge records in, mapped to the
    domains hosted in each. Domains are written without wildcard or trailing dot;
    both the domain and its subdomains are covered.
  EOD
  type = map(list(string))

  default = {
    "Z0237504SXBCD16NK65T" = [
      "dd.soeren.cloud",
      "ez.soeren.cloud",
      "pt.soeren.cloud",
      "rs.soeren.cloud",
      "ch.soeren.cloud"
    ]
  }
}

variable "acmevault_allowed_actions" {
  description = "Route 53 change actions permitted. DELETE is needed for challenge cleanup."
  type        = list(string)
  default     = ["UPSERT", "DELETE"]
}