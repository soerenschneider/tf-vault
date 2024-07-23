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

    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
  }

  backend "s3" {
    bucket = "soerenschneider-terraform"
    key    = "vault-prd"
    region = "us-east-1"
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
  address = "http://localhost:8200"
  token   = "test"
}
