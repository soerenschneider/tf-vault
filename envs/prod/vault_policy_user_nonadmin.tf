resource "vault_policy" "user" {
  name   = "user"
  policy = <<EOT
# List, create, update, and delete key/value secrets
path "${vault_mount.kv.path}/data/users/{{identity.entity.aliases.${vault_auth_backend.userpass.accessor}.name}}/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "${vault_mount.kv.path}/metadata/users/{{identity.entity.aliases.${vault_auth_backend.userpass.accessor}.name}}/*"
{
  capabilities = ["read", "list"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read"]
}

# Read health checks
path "sys/policies/acl"
{
  capabilities = ["read", "list"]
}

path "transit_ansible/encrypt/prod"
{
  capabilities = ["update"]
}

path "transit_ansible/decrypt/prod"
{
  capabilities = ["update"]
}

path "dbs/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh/clients/sign/user"
{
  capabilities = ["update"]
}

path "pki/im_task/issue/human"
{
  capabilities = ["update"]
}

path "pki/im_srn/issue/human"
{
  capabilities = ["update"]
}
EOT
}
