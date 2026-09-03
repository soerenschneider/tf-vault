output "policies" {
  description = "acmevault policies by key."

  value = {
    client = {
      for key, policy in vault_policy.acmevault_client :
      key => policy.name
    }

    server = {
      for key, policy in vault_policy.acmevault_server :
      key => policy.name
    }
  }
}