terraform {
  required_version = ">= 1.6.3"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.11.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "6.63.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      app-role    = "vault"
      project     = "vault.ha.soeren.cloud"
      environment = "prod"
      managed-by  = "terraform"
    }
  }
}

provider "vault" {
  address               = "https://auth.dd.soeren.cloud:8200"
  max_lease_ttl_seconds = 120
}
