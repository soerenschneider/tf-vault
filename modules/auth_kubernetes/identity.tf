resource "vault_identity_entity" "identity" {
  for_each = { for role in var.roles : role.name => role if role.service_account_id != "" }
  name     = format("k8s-%s-%s", var.name, each.key)
  policies = each.value.token_policies
  metadata = merge({ "k8s_cluster" : var.name }, each.value.metadata)
}

resource "vault_identity_entity_alias" "alias" {
  depends_on = [vault_identity_entity.identity]
  for_each   = { for role in var.roles : role.name => role if role.service_account_id != "" }

  # The mapping between an identity and an identity alias happens based on
  # 1. the same mount (accessor, path, type)
  # 2. the same login 'name' for the mount
  # The natural choice would be to use the same human readable name of Kubernetes' svc account, however due to
  # security reasons vault does not use Kubernetes' serviceaccount name by default for the Kubernetes auth.
  # Instead, the svc account id (which is unique compared to the svc account name) is used.
  name            = each.value.service_account_id
  canonical_id    = vault_identity_entity.identity[each.key].id
  mount_accessor  = vault_auth_backend.kubernetes.accessor
  custom_metadata = merge({ "k8s_cluster" : var.name }, each.value.metadata)
}
