locals {
  sops_file = "tg_variables-secrets.sops.yaml"
  secret_vars = yamldecode(sops_decrypt_file(local.sops_file))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = merge(
  local.secret_vars,
  {}
)
