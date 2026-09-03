resource "vault_mount" "intermediate_ca_1" {
  path                      = var.ica_1_mount_path
  type                      = "pki"
  description               = "Intermediate CA 1"
  default_lease_ttl_seconds = var.ica_1_mount_default_lease_ttl
  max_lease_ttl_seconds     = var.ica_1_mount_max_lease_ttl
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_ca_1" {
  depends_on = [vault_mount.intermediate_ca_1]

  backend      = vault_mount.intermediate_ca_1.path
  type         = "internal"
  common_name  = var.ica_1_csr_common_name
  key_type     = var.ica_1_csr_key_type
  key_bits     = var.ica_1_csr_key_bits
  ou           = var.ica_1_csr_ou
  organization = var.ica_1_csr_organization
  country      = var.ica_1_csr_country
  locality     = var.ica_1_csr_locality
  province     = var.ica_1_csr_province
}

resource "local_file" "csr" {
  content  = vault_pki_secret_backend_intermediate_cert_request.intermediate_ca_1.csr
  filename = var.ica_1_csr_output_file
}

data "local_file" "cacert" {
  count = fileexists(var.ica_1_cacert_file) ? 1 : 0

  filename = var.ica_1_cacert_file
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate_ca_1_signed_cert" {
  count = fileexists(var.ica_1_cacert_file) ? 1 : 0

  depends_on  = [vault_mount.intermediate_ca_1]
  backend     = vault_mount.intermediate_ca_1.path
  certificate = data.local_file.cacert[0].content
}
