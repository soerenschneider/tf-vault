locals {
  default_role_id_from_role_name = true
}

resource "vault_approle_auth_backend_role" "approle" {
  for_each = { for role in var.approles : role.role_name => role }

  backend               = var.approle_mount_path
  role_name             = each.value.role_name
  role_id               = coalesce(each.value.role_id_from_role_name, local.default_role_id_from_role_name) ? each.value.role_name : each.value.role_id
  token_policies        = concat([vault_policy.approle_rotation.name], try(each.value.token_policies, []))
  token_max_ttl         = each.value.token_max_ttl
  token_ttl             = each.value.token_ttl
  token_bound_cidrs     = coalescelist(each.value.token_bound_cidrs, try(var.cidr_map[regex(var.name_cidr_regex, each.value.role_name)[0]], []), [])
  secret_id_bound_cidrs = coalescelist(each.value.secret_id_bound_cidrs, try(var.cidr_map[regex(var.name_cidr_regex, each.value.role_name)[0]], []), [])
  secret_id_ttl         = each.value.secret_id_ttl
  secret_id_num_uses    = each.value.secret_id_num_uses
}

resource "vault_identity_entity" "approle_identity" {
  for_each = { for role in var.approles : role.role_name => role if role.create_identity }
  name     = each.value.role_name
  policies = each.value.token_policies
  metadata = each.value.identity_metadata
}

resource "vault_identity_entity_alias" "approle_identity_alias" {
  depends_on = [vault_identity_entity.approle_identity]
  for_each   = { for role in var.approles : role.role_name => role if role.create_identity }

  name            = each.value.role_name
  canonical_id    = vault_identity_entity.approle_identity[each.value.role_name].id
  mount_accessor  = var.approle_mount_accessor
  custom_metadata = each.value.identity_metadata
}
