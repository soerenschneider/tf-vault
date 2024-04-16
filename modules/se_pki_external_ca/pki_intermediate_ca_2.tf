resource "vault_mount" "intermediate_ca_2" {
  path                      = var.ica_2_mount_path
  type                      = "pki"
  description               = "Intermediate CA 2"
  default_lease_ttl_seconds = var.ica_2_mount_default_lease_ttl
  max_lease_ttl_seconds     = var.ica_2_mount_max_lease_ttl
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_ca_2" {
  depends_on   = [vault_mount.intermediate_ca_2]
  backend      = vault_mount.intermediate_ca_2.path
  type         = "internal"
  common_name  = var.ica_2_csr_common_name
  key_type     = var.ica_2_csr_key_type
  key_bits     = var.ica_2_csr_key_bits
  ou           = var.ica_2_csr_ou
  organization = var.ica_2_csr_organization
  country      = var.ica_2_csr_country
  locality     = var.ica_2_csr_locality
  province     = var.ica_2_csr_province
}

resource "vault_pki_secret_backend_root_sign_intermediate" "ica2_signed_intermediate" {
  count = fileexists(var.ica_1_cacert_file) ? 1 : 0

  depends_on = [
    vault_mount.intermediate_ca_1,
    vault_pki_secret_backend_intermediate_cert_request.intermediate_ca_2,
  ]
  backend              = vault_mount.intermediate_ca_1.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate_ca_2.csr
  common_name          = "Intermediate CA2 v1.1"
  exclude_cn_from_sans = true
  ou                   = var.ica_2_csr_ou
  organization         = var.ica_2_csr_organization
  country              = var.ica_2_csr_country
  locality             = var.ica_2_csr_locality
  province             = var.ica_2_csr_province

  max_path_length = 0
  ttl             = 31536000
}

resource "vault_pki_secret_backend_intermediate_set_signed" "ica2_signed_intermediate" {
  depends_on  = [vault_pki_secret_backend_root_sign_intermediate.ica2_signed_intermediate]
  backend     = vault_mount.intermediate_ca_2.path
  certificate = format("%s\n%s", vault_pki_secret_backend_root_sign_intermediate.ica2_signed_intermediate[0].certificate, data.local_file.cacert[0].content)
  count       = fileexists(var.ica_1_cacert_file) ? 1 : 0
}
