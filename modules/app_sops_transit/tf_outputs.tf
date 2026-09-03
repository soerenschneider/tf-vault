output path {
  value = vault_mount.transit.path
}

output "policies" {
  description = "SOPS Transit policies by key."

  value = {
    encrypt = {
      for key, policy in vault_policy.transit_encrypt :
      key => policy.name
    }

    decrypt = {
      for key, policy in vault_policy.transit_decrypt :
      key => policy.name
    }

    encrypt_decrypt = {
      for key, policy in vault_policy.transit_encrypt_decrypt :
      key => policy.name
    }
  }
}