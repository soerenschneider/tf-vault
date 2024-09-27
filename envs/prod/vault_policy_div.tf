resource "vault_policy" "kv2_machine" {
  name   = "kv2_machine"
  policy = <<EOT
path "${vault_mount.kv.path}/data/machine/{{identity.entity.metadata.host}}/*" {
  capabilities = ["read"]
}
EOT
}
