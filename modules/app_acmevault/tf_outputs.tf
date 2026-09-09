output "policies" {
  description = "acmevault policies by key."

  value = {
    client = vault_policy.acmevault_client.name
    server = vault_policy.acmevault_server.name
  }
}