resource "vault_policy" "kv2_machine" {
  name   = "kv2_machine"
  policy = <<EOT
path "${vault_mount.kv.path}/data/machine/{{identity.entity.aliases.${vault_auth_backend.approle.accessor}.metadata.host}}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "kv2_machine_vserver_ez" {
  name   = "kv2_machine_vserver_ez"
  policy = <<EOT
path "${vault_mount.kv.path}/data/machine/vserver.ez.soeren.cloud/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "kv2_machine_vserver_pt" {
  name   = "kv2_machine_vserver_pt"
  policy = <<EOT
path "${vault_mount.kv.path}/data/machine/vserver.pt.soeren.cloud/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "kv2_machine_vserver_dd" {
  name   = "kv2_machine_vserver_dd"
  policy = <<EOT
path "${vault_mount.kv.path}/data/machine/vserver.dd.soeren.cloud/*" {
  capabilities = ["read"]
}
EOT
}
