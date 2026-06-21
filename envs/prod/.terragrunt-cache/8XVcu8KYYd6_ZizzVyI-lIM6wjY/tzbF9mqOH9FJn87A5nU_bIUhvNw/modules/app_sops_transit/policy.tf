resource "vault_policy" "transit_principal" {
  name   = "transit_sops_${var.name}_principal"
  policy = <<EOT
path "${vault_mount.transit.path}/encrypt/*" {
   capabilities = [ "update" ]
}

path "${vault_mount.transit.path}/decrypt/*" {
   capabilities = [ "update" ]
}
EOT
}

resource "vault_policy" "transit" {
  for_each = var.environments
  name     = "transit_sops_${var.name}_${each.value}"
  policy   = <<EOT
path "${vault_mount.transit.path}/encrypt/${each.value}" {
   capabilities = [ "update" ]
}

path "${vault_mount.transit.path}/decrypt/${each.value}" {
   capabilities = [ "update" ]
}
EOT
}