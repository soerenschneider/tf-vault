locals {
  rate_limits = {
    global = {
      path = "",
      rate = 500
    }

    kv = {
      path = "${trimsuffix(vault_mount.kv.path, "/")}/",
      rate = 50
    }

    auth = {
      path = "auth/token/",
      rate = 100
    }

    userpass = {
      path           = "auth/${trimsuffix(vault_auth_backend.userpass.path, "/")}/",
      rate           = 20
      interval       = 60
      block_interval = 300
    }

    mfa = {
      path           = "sys/mfa/validate",
      rate           = 10,
      interval       = 60,
      block_interval = 300
    }
  }
}

resource "vault_quota_rate_limit" "this" {
  for_each = local.rate_limits

  name           = each.key
  path           = each.value.path
  rate           = each.value.rate
  interval       = try(each.value.interval, 1)
  block_interval = try(each.value.block_interval, 0)
}