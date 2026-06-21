resource "vault_policy" "admin" {
  name   = "admin"
  policy = <<EOT
# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Read audit methods
path "sys/audit"
{
  capabilities = ["read", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

path "sys/quotas/rate-limit/global"
{
  capabilities = ["read", "update"]
}

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete key/value secrets
path "${var.kv2_mount}/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage quotas
path "sys/quotas/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

path "aws/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "identity/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit_ansible/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit_vault_unsealer/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "dbs/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kubernetes/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "pki/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOT
}
