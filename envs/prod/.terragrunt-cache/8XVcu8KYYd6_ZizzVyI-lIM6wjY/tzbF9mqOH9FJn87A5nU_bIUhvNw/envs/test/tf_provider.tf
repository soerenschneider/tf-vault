terraform {
  required_version = ">= 1.6.3"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.8.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "5.21.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }
  }
}

provider "vault" {
  address               = "http://localhost:8200"
  max_lease_ttl_seconds = 120
  token = "test"
}
