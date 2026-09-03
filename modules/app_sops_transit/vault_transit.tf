resource "vault_mount" "transit" {
  path                      = "transit/sops_${var.name}"
  type                      = "transit"
  description               = "transit for sops ${var.name}"
  default_lease_ttl_seconds = var.ttl_seconds
  max_lease_ttl_seconds     = var.ttl_max_seconds
}

locals {
  keys = var.keys != null && length(var.keys) > 0 ? var.keys : toset(["default"])
}

resource "vault_transit_secret_backend_key" "key" {
  for_each         = local.keys
  backend          = vault_mount.transit.path
  name             = each.value
  exportable       = false
  deletion_allowed = var.deletion_allowed
  type             = "aes256-gcm96"
}

resource "vault_policy" "transit_encrypt" {
  for_each = local.keys

  name = "transit_sops_${var.name}_${each.value}_encrypt"

  policy = <<EOT
path "${vault_mount.transit.path}/encrypt/${each.value}" {
  capabilities = ["update"]
}
EOT
}

resource "vault_policy" "transit_decrypt" {
  for_each = local.keys

  name = "transit_sops_${var.name}_${each.value}_decrypt"

  policy = <<EOT
path "${vault_mount.transit.path}/decrypt/${each.value}" {
  capabilities = ["update"]
}
EOT
}

resource "vault_policy" "transit_encrypt_decrypt" {
  for_each = local.keys

  name = "transit_sops_${var.name}_${each.value}"

  policy = <<EOT
path "${vault_mount.transit.path}/encrypt/${each.value}" {
  capabilities = ["update"]
}

path "${vault_mount.transit.path}/decrypt/${each.value}" {
  capabilities = ["update"]
}
EOT
}