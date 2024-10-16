resource "vault_policy" "kv2_machine" {
  name   = "kv2_machine"
  policy = <<EOT
path "${vault_mount.kv.path}/data/machine/{{ identity.entity.metadata.host }}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "prometheus" {
  name = "prometheus"

  policy = <<EOT
path "/sys/metrics*" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_policy" "soeren_cloud" {
  name   = "soeren_cloud"
  policy = <<EOT
path "${vault_mount.kv.path}/data/machine/{{ identity.entity.metadata.host }}/*" {
  capabilities = ["read"]
}

path "${vault_mount.kv.path}/data/soeren.cloud/dc/{{ identity.entity.metadata.datacenter }}/*" {
  capabilities = ["read"]
}

path "${vault_mount.kv.path}/data/soeren.cloud/env/{{ identity.entity.metadata.environment }}/*" {
  capabilities = ["read"]
}

path "${vault_mount.kv.path}/data/soeren.cloud/k8s/{{ identity.entity.metadata.k8s_cluster }}/*" {
  capabilities = ["read"]
}
EOT
}
