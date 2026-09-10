terraform {
  # 1.3+ is required for optional() object attributes with defaults.
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.11.0"
    }
  }
}
