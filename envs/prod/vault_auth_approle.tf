resource "vault_auth_backend" "approle" {
  type = "approle"
}

module "approles" {
  source                 = "../../modules/auth_approle"
  approle_mount_accessor = vault_auth_backend.approle.accessor
  approle_mount_path     = vault_auth_backend.approle.path
  approles               = local.vault_approles
}

resource "vault_identity_group" "approle" {
  #for_each  = { for k, approle in distinct(flatten(try(local.approles[*].groups, []))) : approle => approle }
  for_each = {
    for group in var.identity_groups : group.name => group
  }
  member_entity_ids = [
    for entry in local.vault_approles : module.approles.approle_identities[entry.role_name] if lookup(entry, "groups", null) != null
  ]
  name     = each.value.name
  type     = "internal"
  policies = each.value.policies
}

locals {
  approles_definition_file = "approles.yaml"
  ip_ranges = {
    "router.dd.soeren.cloud" : ["192.168.200.3/32"]
    "router.ez.soeren.cloud" : ["192.168.200.2/32"]
    "router.pt.soeren.cloud" : ["192.168.200.4/32"]
    "dd.soeren.cloud" : ["192.168.64.0/21"]
    "ez.soeren.cloud" : ["192.168.2.0/24"]
    "pt.soeren.cloud" : ["192.168.72.0/21"]
    "rs.soeren.cloud" : ["192.168.200.1/32"]
    "ch.soeren.cloud" : ["192.168.200.5/32"]
  }
  ip_ranges_fallback = ["192.168.0.0/16"]

  vault_approles = concat(var.approles, [
    for vault in yamldecode(file(local.approles_definition_file)) : merge(
      vault, {
        "token_bound_cidrs" = coalescelist(
          lookup(vault, "token_bound_cidrs", []),
          coalescelist(flatten([for regex, value in local.ip_ranges : value if endswith(vault.role_name, regex)]), local.ip_ranges_fallback),
        )
        "secret_id_bound_cidrs" = coalescelist(
          lookup(vault, "secret_id_bound_cidrs", []),
          coalescelist(flatten([for regex, value in local.ip_ranges : value if endswith(vault.role_name, regex)]), local.ip_ranges_fallback),
        )
      }
  )])
}
