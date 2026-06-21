resource "vault_mount" "transit" {
  path                      = "transit/sops_${var.name}"
  type                      = "transit"
  description               = "transit for sops ${var.name}"
  default_lease_ttl_seconds = var.ttl_seconds
  max_lease_ttl_seconds     = var.ttl_max_seconds
}

resource "vault_transit_secret_backend_key" "key" {
  for_each         = var.environments
  backend          = vault_mount.transit.path
  name             = each.value
  exportable       = false
  deletion_allowed = var.deletion_allowed
  type             = "aes256-gcm96"
}
