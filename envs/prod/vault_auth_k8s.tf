module "k8s_auth" {
  source             = "../../modules/auth_kubernetes"
  for_each           = var.auth_k8s
  name               = each.key
  mount_path         = each.key
  host               = each.value.host
  ca_cert            = each.value.ca_cert != null ? each.value.ca_cert : file(each.value.ca_cert_file)
  token_reviewer_jwt = each.value.token_reviewer_jwt
  roles              = each.value.roles
}

resource "vault_policy" "k8s-kv2" {
  for_each = var.auth_k8s
  name     = "k8s-kv2-${each.key}"

  policy = <<EOF
path "${var.kv2_mount}/data/${each.key}/*" {
  capabilities = ["read", "list"]
}
EOF
}
