resource "vault_kubernetes_secret_backend" "backend" {
  path                      = var.mount_path
  default_lease_ttl_seconds = var.default_ttl_lease_seconds
  max_lease_ttl_seconds     = var.max_ttl_lease_seconds
  kubernetes_host           = var.host
  kubernetes_ca_cert        = var.ca_cert
  service_account_jwt       = var.service_account_jwt
}

resource "vault_kubernetes_secret_backend_role" "role" {
  for_each                      = { for idx, val in var.roles : idx => val }
  backend                       = vault_kubernetes_secret_backend.backend.path
  name                          = each.value.name
  allowed_kubernetes_namespaces = each.value.allowed_namespaces
  token_default_ttl             = each.value.token_default_ttl
  token_max_ttl                 = each.value.token_max_ttl
  kubernetes_role_name          = each.value.kubernetes_role_name
  kubernetes_role_type          = each.value.kubernetes_role_type
  service_account_name          = each.value.service_account_name
  extra_labels                  = each.value.extra_labels
  extra_annotations             = each.value.extra_annotations
}

resource "vault_policy" "k8s" {
  for_each = {
    for index, role in var.roles : index => role
  }
  name = "k8s_${var.identifier}_${each.value.name}"

  policy = <<EOT
path "${var.mount_path}/creds/${each.value.name}" {
  capabilities = ["update"]
}
EOT
}
