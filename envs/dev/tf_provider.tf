terraform {
  required_version = ">= 1.6.3"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "4.4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}

provider "vault" {
  address = "http://localhost:8200"
  token   = "test"
}
