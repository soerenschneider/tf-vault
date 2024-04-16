resource "vault_policy" "transit" {
  for_each = var.environments
  name     = "ansible_${each.value}"
  policy   = <<EOT
path "${var.mount_path}/encrypt/${each.value}" {
   capabilities = [ "update" ]
}

path "${var.mount_path}/decrypt/${each.value}" {
   capabilities = [ "update" ]
}
EOT
}
