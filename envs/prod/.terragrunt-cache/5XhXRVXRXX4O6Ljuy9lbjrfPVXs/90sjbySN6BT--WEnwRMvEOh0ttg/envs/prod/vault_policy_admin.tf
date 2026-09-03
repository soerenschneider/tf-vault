resource "vault_policy" "admin" {
  name = "admin"

  # Configuration-plane admin. Manages mounts, auth methods, engine config
  # and roles. Deliberately excludes the data plane: no KV secret access, no
  # certificate issuance, no dynamic credential generation, no crypto ops.
  #
  # NOT a security boundary: this role can write ACL policies and manage
  # identity, so it can grant itself anything denied below. The value is
  # accident prevention plus a loud audit tripwire — any data access from
  # this role must be preceded by a policy write.
  #
  # Uses `+` (single-segment wildcard) to cover nested mounts such as
  # ssh/servers, transit/sops, pki/internal. See LIMITATION note below.

  policy = <<-EOT
    # ======================= system =======================

    path "sys/mounts" {
      capabilities = ["read", "list"]
    }
    path "sys/mounts/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    path "sys/remount" {
      capabilities = ["create", "update"]
    }

    path "sys/auth" {
      capabilities = ["read", "list"]
    }
    path "sys/auth/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    path "sys/policies/acl" {
      capabilities = ["list"]
    }
    path "sys/policies/acl/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "sys/quotas/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "sys/audit" {
      capabilities = ["read", "list", "sudo"]
    }
    path "sys/audit/*" {
      capabilities = ["create", "read", "update", "delete", "sudo"]
    }

    path "sys/leases/lookup/*" {
      capabilities = ["create", "update", "list"]
    }
    path "sys/leases/revoke/*" {
      capabilities = ["create", "update"]
    }
    path "sys/leases/revoke-prefix/*" {
      capabilities = ["create", "update", "sudo"]
    }

    path "sys/health" {
      capabilities = ["read"]
    }
    path "sys/capabilities-self" {
      capabilities = ["create", "update"]
    }
    path "sys/internal/ui/mounts" {
      capabilities = ["read"]
    }
    path "sys/internal/ui/mounts/*" {
      capabilities = ["read"]
    }

    # Bypass everything below — never grant these here.
    path "sys/raw/*" {
      capabilities = ["deny"]
    }
    path "sys/storage/raft/snapshot" {
      capabilities = ["deny"]
    }
    path "sys/plugins/catalog/*" {
      capabilities = ["deny"]
    }

    # ======================= auth methods =======================

    path "auth/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
    # Terraform has no reason to mint tokens.
    path "auth/token/create-orphan" {
      capabilities = ["deny"]
    }

    # ======================= identity =======================

    path "identity/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    # ======================= SSH =======================
    # Allowed: config/ca, roles, zeroaddress, verify.
    # Denied: certificate signing and credential issuance.

    path "ssh/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "ssh/sign/*" {
      capabilities = ["deny"]
    }
    path "ssh/+/sign/*" {
      capabilities = ["deny"]
    }
    path "ssh/issue/*" {
      capabilities = ["deny"]
    }
    path "ssh/+/issue/*" {
      capabilities = ["deny"]
    }
    path "ssh/creds/*" {
      capabilities = ["deny"]
    }
    path "ssh/+/creds/*" {
      capabilities = ["deny"]
    }

    # ======================= PKI =======================
    # Allowed: roles, config/urls, config/crl, tidy, CRL rotation, issuer metadata.
    # Denied: all leaf issuance and signing.

    path "pki/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "pki/issue/*" {
      capabilities = ["deny"]
    }
    path "pki/+/issue/*" {
      capabilities = ["deny"]
    }
    path "pki/sign/*" {
      capabilities = ["deny"]
    }
    path "pki/+/sign/*" {
      capabilities = ["deny"]
    }
    path "pki/sign-verbatim" {
      capabilities = ["deny"]
    }
    path "pki/sign-verbatim/*" {
      capabilities = ["deny"]
    }
    path "pki/+/sign-verbatim" {
      capabilities = ["deny"]
    }
    path "pki/+/sign-verbatim/*" {
      capabilities = ["deny"]
    }

    # Per-issuer variants of the above.
    path "pki/issuer/+/issue/*" {
      capabilities = ["deny"]
    }
    path "pki/+/issuer/+/issue/*" {
      capabilities = ["deny"]
    }
    path "pki/issuer/+/sign/*" {
      capabilities = ["deny"]
    }
    path "pki/+/issuer/+/sign/*" {
      capabilities = ["deny"]
    }
    path "pki/issuer/+/sign-verbatim" {
      capabilities = ["deny"]
    }
    path "pki/+/issuer/+/sign-verbatim" {
      capabilities = ["deny"]
    }

    # ======================= transit =======================
    # Allowed: key lifecycle (create, rotate, config, trim, delete), import.
    # Denied: all crypto operations and any path returning key material.

    path "transit/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "transit/encrypt/*" {
      capabilities = ["deny"]
    }
    path "transit/+/encrypt/*" {
      capabilities = ["deny"]
    }
    path "transit/decrypt/*" {
      capabilities = ["deny"]
    }
    path "transit/+/decrypt/*" {
      capabilities = ["deny"]
    }
    path "transit/rewrap/*" {
      capabilities = ["deny"]
    }
    path "transit/+/rewrap/*" {
      capabilities = ["deny"]
    }
    path "transit/sign/*" {
      capabilities = ["deny"]
    }
    path "transit/+/sign/*" {
      capabilities = ["deny"]
    }
    path "transit/verify/*" {
      capabilities = ["deny"]
    }
    path "transit/+/verify/*" {
      capabilities = ["deny"]
    }
    path "transit/hmac/*" {
      capabilities = ["deny"]
    }
    path "transit/+/hmac/*" {
      capabilities = ["deny"]
    }
    path "transit/datakey/*" {
      capabilities = ["deny"]
    }
    path "transit/+/datakey/*" {
      capabilities = ["deny"]
    }
    path "transit/export/*" {
      capabilities = ["deny"]
    }
    path "transit/+/export/*" {
      capabilities = ["deny"]
    }
    path "transit/backup/*" {
      capabilities = ["deny"]
    }
    path "transit/+/backup/*" {
      capabilities = ["deny"]
    }

    # ======================= AWS =======================

    path "aws/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "aws/creds/*" {
      capabilities = ["deny"]
    }
    path "aws/+/creds/*" {
      capabilities = ["deny"]
    }
    path "aws/sts/*" {
      capabilities = ["deny"]
    }
    path "aws/+/sts/*" {
      capabilities = ["deny"]
    }

    path "aws/+/creds/admin" {
      capabilities = ["read"]
    }

    # ======================= database =======================

    path "dbs/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "dbs/creds/*" {
      capabilities = ["deny"]
    }
    path "dbs/+/creds/*" {
      capabilities = ["deny"]
    }
    path "dbs/static-creds/*" {
      capabilities = ["deny"]
    }
    path "dbs/+/static-creds/*" {
      capabilities = ["deny"]
    }

    # ======================= Kubernetes secrets engine =======================

    path "kubernetes/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "kubernetes/creds/*" {
      capabilities = ["deny"]
    }
    path "kubernetes/+/creds/*" {
      capabilities = ["deny"]
    }

    # ======================= KV v2 =======================
    # No broad allow here. Only mount config plus metadata listing, so paths
    # are visible but values are not. Explicit denies as belt and braces.

    path "${var.kv2_mount}/config" {
      capabilities = ["read", "update"]
    }
    path "${var.kv2_mount}/metadata/*" {
      capabilities = ["list"]
    }

    path "${var.kv2_mount}/data/*" {
      capabilities = ["deny"]
    }
    path "${var.kv2_mount}/subkeys/*" {
      capabilities = ["deny"]
    }
    path "${var.kv2_mount}/delete/*" {
      capabilities = ["deny"]
    }
    path "${var.kv2_mount}/undelete/*" {
      capabilities = ["deny"]
    }
    path "${var.kv2_mount}/destroy/*" {
      capabilities = ["deny"]
    }

    # ======================= optional: CA / root material =======================
    # Uncomment to also block paths that return or set signing keys. These are
    # strictly more powerful than the leaf issuance denied above: whoever sets
    # ssh CA or exports a PKI root can sign offline, with no Vault involvement.
    # Cost: CA bootstrap and rotation move to break-glass.
    #
    # path "ssh/config/ca"                    { capabilities = ["deny"] }
    # path "ssh/+/config/ca"                  { capabilities = ["deny"] }
    # path "pki/root/generate/*"              { capabilities = ["deny"] }
    # path "pki/+/root/generate/*"            { capabilities = ["deny"] }
    # path "pki/root/sign-intermediate"       { capabilities = ["deny"] }
    # path "pki/+/root/sign-intermediate"     { capabilities = ["deny"] }
    # path "pki/intermediate/generate/*"      { capabilities = ["deny"] }
    # path "pki/+/intermediate/generate/*"    { capabilities = ["deny"] }
    # path "aws/config/root"                  { capabilities = ["deny"] }
    # path "aws/+/config/root"                { capabilities = ["deny"] }
  EOT
}