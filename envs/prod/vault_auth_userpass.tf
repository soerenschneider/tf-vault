resource "vault_identity_mfa_totp" "totp" {
  issuer                  = "Vault HA prod"
  max_validation_attempts = 2
}

resource "vault_identity_mfa_login_enforcement" "example" {
  name = "default"
  mfa_method_ids = [
    vault_identity_mfa_totp.totp.id,
  ]
  auth_method_types = [
    "userpass"
  ]
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"
  tune {
    max_lease_ttl = "86400s"
  }
}

resource "vault_userpass_auth_backend_user" "user" {
  for_each = { for u in var.users : u.name => u }

  mount               = vault_auth_backend.userpass.path
  username            = each.value.name
  password_wo         = "changeme"
  password_wo_version = 1

  token_policies         = each.value.token_policies
  token_ttl              = each.value.token_ttl
  token_max_ttl          = each.value.token_max_ttl
  token_explicit_max_ttl = each.value.token_explicit_max_ttl
  token_num_uses         = each.value.token_num_uses
  token_bound_cidrs      = each.value.token_bound_cidrs
}