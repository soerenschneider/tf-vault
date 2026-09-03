resource "vault_identity_entity" "identities" {
  for_each = { for key, val in var.identities : key => val }
  name     = each.key
  policies = each.value.policies
  metadata = each.value.metadata
}

output "identities" {
  value = {
    for k, v in vault_identity_entity.identities : k => vault_identity_entity.identities[k].id
  }
}

resource "vault_identity_entity_alias" "aliases" {
  for_each       = { for key, val in var.identities : key => val }
  name           = each.key
  mount_accessor = vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.identities[each.key].id
}
