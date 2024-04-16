resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.mount_path
}

resource "vault_kubernetes_auth_backend_config" "example" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = var.host
  kubernetes_ca_cert     = var.ca_cert
  token_reviewer_jwt     = var.token_reviewer_jwt
  disable_iss_validation = true
}
