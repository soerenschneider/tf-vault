terraform {
  required_version = ">= 1.6.3"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "4.5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
  }
}
