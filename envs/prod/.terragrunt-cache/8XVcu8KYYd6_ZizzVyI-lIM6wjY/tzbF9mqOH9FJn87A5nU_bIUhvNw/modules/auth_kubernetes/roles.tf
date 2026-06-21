resource "vault_kubernetes_auth_backend_role" "acmevault" {
  for_each                         = { for role in var.roles : role.name => role }
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = each.value.name
  bound_service_account_names      = each.value.bound_svc_account_names
  bound_service_account_namespaces = each.value.bound_namespaces
  token_ttl                        = each.value.token_ttl
  token_policies                   = each.value.token_policies
  audience                         = each.value.audience
}
