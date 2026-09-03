locals {
  sops_file = "tg_variables-secrets.sops.yaml"
  secret_vars = yamldecode(sops_decrypt_file(local.sops_file))
}

inputs = merge(
  local.secret_vars,
  {}
)
