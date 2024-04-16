resource "vault_mount" "transit" {
  path                      = var.mount_path
  type                      = "transit"
  description               = "vault unsealer transit"
  default_lease_ttl_seconds = var.default_lease_ttl
  max_lease_ttl_seconds     = var.max_lease_ttl
}

resource "vault_transit_secret_backend_key" "key" {
  for_each         = { for env in var.environments : env => env }
  backend          = vault_mount.transit.path
  deletion_allowed = false
  name             = each.key
}

resource "vault_policy" "transit_user" {
  for_each = { for env in var.environments : env => env }
  name     = "app_vault_unsealer_${each.key}"
  policy   = <<EOT
path "${vault_mount.transit.path}/decrypt/${each.key}" {
  capabilities = ["update"]
}

path "${vault_mount.transit.path}/encrypt/${each.key}" {
  capabilities = ["update"]
}
EOT
}
