resource "vault_token_auth_backend_role" "emergency" {
  role_name         = "emergency_seal"
  allowed_policies  = [vault_policy.emergency.name]
  token_bound_cidrs = var.token_bound_cidrs
  orphan            = true
}

resource "vault_token" "emergency" {
  role_name       = vault_token_auth_backend_role.emergency.role_name
  policies        = [vault_policy.emergency.name]
  display_name    = "emergency-seal"
  renewable       = true
  num_uses        = 1
  ttl             = var.token_ttl
  renew_min_lease = 2592000
  renew_increment = 7776000
}
