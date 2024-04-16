terraform {
  required_version = ">= 1.6.3"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.21.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
  }
}