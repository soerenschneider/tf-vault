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
  #hosts_approles_defined = flatten([for hosts_key, hosts_value in try(yamldecode(file(var.hosts_definition_file)), {}) : [
  hosts_approles_defined = length(var.hosts_definition_file) == 0 ? [] : flatten([for hosts_key, hosts_value in yamldecode(file(var.hosts_definition_file)) : [
    for location_key, location_values in hosts_value : [
      for host in location_values : host if lookup(host, "vault_approles", null) != null
    ]
    ] if hosts_key == "local_hosts"
  ])

  vault_approles = concat(var.approles, flatten([for host in local.hosts_approles_defined : [
    for vault in host.vault_approles : merge(
      vault, {
        "token_bound_cidrs"     = coalescelist(lookup(vault, "token_bound_cidrs", []), tolist([format("%s/24", host.logical)])) # https://github.com/hashicorp/vault/issues/11961
        "secret_id_bound_cidrs" = coalescelist(lookup(vault, "secret_id_bound_cidrs", []), tolist([format("%s/32", host.logical)]))
      }
    )]
  ]))
}
