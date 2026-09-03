locals {
  # Resolved by Vault at request time from the userpass alias.
  user = "{{identity.entity.aliases.${vault_auth_backend.userpass.accessor}.name}}"

  kv_path  = vault_mount.kv.path
  ssh_path = module.se_ssh["clients"].mount_path
}

resource "vault_policy" "users" {
  name = "users"

  policy = <<-EOT
    # ---------------------------------------------------------------
    # Own KV v2 secrets (kv/users/<username>/...)
    # ---------------------------------------------------------------

    # Secret at the user's own root, e.g. `vault kv put kv/users/alice ...`
    path "${local.kv_path}/data/users/${local.user}" {
      capabilities = ["create", "read", "update", "patch", "delete"]
    }

    path "${local.kv_path}/data/users/${local.user}/*" {
      capabilities = ["create", "read", "update", "patch", "delete"]
    }

    # Listing and version history go through metadata/ in KV v2.
    # `delete` here purges every version — drop it if that's too much.
    path "${local.kv_path}/metadata/users/${local.user}" {
      capabilities = ["read", "list", "delete"]
    }

    path "${local.kv_path}/metadata/users/${local.user}/*" {
      capabilities = ["read", "list", "delete"]
    }

    # Needed by `vault kv patch` and the UI's partial-edit flow.
    path "${local.kv_path}/subkeys/users/${local.user}/*" {
      capabilities = ["read"]
    }

    # Real (hard) deletes of individual versions.
    path "${local.kv_path}/delete/users/${local.user}/*" {
      capabilities = ["update"]
    }

    path "${local.kv_path}/undelete/users/${local.user}/*" {
      capabilities = ["update"]
    }

    path "${local.kv_path}/destroy/users/${local.user}/*" {
      capabilities = ["update"]
    }

    # ---------------------------------------------------------------
    # Self-service password change
    # ---------------------------------------------------------------
    # Dedicated endpoint — cannot touch token_policies or other user config.
    path "auth/${vault_auth_backend.userpass.path}/users/${local.user}/password" {
      capabilities = ["update"]
    }

    # ---------------------------------------------------------------
    # SSH client certificates
    # ---------------------------------------------------------------
    # One role per user. If you switch the SSH mount to a single shared role
    # with allowed_users_template/default_user_template, replace this with a
    # fixed path and let Vault enforce the principal.
    path "${local.ssh_path}/sign/${local.user}" {
      capabilities = ["update"]
    }
    path "${local.ssh_path}/sign/users" {
      capabilities = ["update"]
    }

    # ---------------------------------------------------------------
    # Introspection
    # ---------------------------------------------------------------
    # Read the policy that applies to you.
    path "sys/policies/acl/users" {
      capabilities = ["read"]
    }

    # ---------------------------------------------------------------
    # Web UI support (drop this block if CLI/API only)
    # ---------------------------------------------------------------
    path "sys/internal/ui/mounts" {
      capabilities = ["read"]
    }

    path "sys/internal/ui/mounts/*" {
      capabilities = ["read"]
    }

    path "sys/internal/ui/resultant-acl" {
      capabilities = ["read"]
    }
  EOT
}