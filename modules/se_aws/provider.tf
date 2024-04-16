terraform {
  required_version = ">= 1.6.3"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.21.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.21.0"
    }
  }
}