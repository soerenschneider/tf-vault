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

resource "vault_quota_rate_limit" "userpass" {
  name           = "userpass"
  path           = "auth/${vault_auth_backend.userpass.path}"
  rate           = 500
  interval       = 1
  block_interval = 60
}

resource "vault_generic_endpoint" "user_initial_pass" {
  for_each             = { for idx, val in var.users : idx => val }
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/${vault_auth_backend.userpass.path}/users/${each.value.name}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "password": "changeme"
}
EOT
}

resource "vault_generic_endpoint" "user" {
  for_each             = { for idx, val in var.users : idx => val }
  depends_on           = [vault_generic_endpoint.user_initial_pass]
  path                 = "auth/${vault_auth_backend.userpass.path}/users/${each.value.name}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "token_policies": ${jsonencode(each.value.token_policies)},
  "token_ttl": ${jsonencode(each.value.token_ttl)},
  "token_max_ttl": ${jsonencode(each.value.token_max_ttl)},
  "token_explicit_max_ttl": ${jsonencode(each.value.token_explicit_max_ttl)},
  "token_num_uses": ${jsonencode(each.value.token_num_uses)},
  "token_bound_cidrs": ${jsonencode(each.value.token_bound_cidrs)}
}
EOT
}