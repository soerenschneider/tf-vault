resource "vault_quota_rate_limit" "global" {
  name = "global"
  path = ""
  rate = 500
}

resource "vault_quota_rate_limit" "kv" {
  name = "kv"
  path = vault_mount.kv.path
  rate = 10
}

resource "vault_quota_rate_limit" "auth" {
  name = "auth"
  path = "auth/token"
  rate = 50
}

resource "vault_quota_rate_limit" "mfa" {
  name           = "mfa"
  path           = "sys/mfa/validate"
  rate           = 10
  interval       = 60
  block_interval = 60
}
