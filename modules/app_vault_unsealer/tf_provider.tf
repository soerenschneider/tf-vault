terraform {
  required_version = ">= 1.6.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.11.0"
    }
  }
}
