resource "vault_mount" "pki_intermediate" {
  path        = var.intermediate_mount_path
  type        = "pki"
  description = "Intermediate CA"

  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = var.intermediate_mount_max_ttl
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  backend              = vault_mount.pki_intermediate.path
  type                 = "internal"
  common_name          = var.intermediate_common_name
  format               = var.intermediate_format
  private_key_format   = var.intermediate_private_key_format
  key_type             = var.intermediate_key_type
  key_bits             = var.intermediate_key_bits
  exclude_cn_from_sans = true
  ou                   = var.intermediate_ou
  organization         = var.intermediate_organization
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  depends_on           = [vault_pki_secret_backend_intermediate_cert_request.intermediate]
  backend              = vault_mount.pki_root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name          = "${var.cert_domain} Intermediate Certificate"
  exclude_cn_from_sans = true
  ou                   = var.intermediate_ou
  organization         = var.intermediate_organization
  ttl                  = var.intermediate_ttl
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend = vault_mount.pki_intermediate.path

  certificate = "${vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate}\n${vault_pki_secret_backend_root_cert.root.certificate}"
}
