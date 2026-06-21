output "approle_identity_ids" {
  value = [for entry in vault_identity_entity.approle_identity : entry.id]
}

output "approle_identities" {
  value = { for entry in vault_identity_entity.approle_identity : entry.name => entry.id }
}
