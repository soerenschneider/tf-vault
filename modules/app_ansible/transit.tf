resource "vault_mount" "transit" {
  path                      = var.mount_path
  type                      = "transit"
  description               = "Ansible transit keys"
  default_lease_ttl_seconds = var.ttl_seconds
  max_lease_ttl_seconds     = var.ttl_max_seconds
}

resource "vault_transit_secret_backend_key" "key" {
  for_each = var.environments

  backend    = vault_mount.transit.path
  name       = each.value
  exportable = false
  type       = "aes256-gcm96"
}
