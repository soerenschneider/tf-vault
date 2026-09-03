resource "vault_policy" "acmevault_client" {
  name = "acmevault_client"

  policy = <<EOT
path "${var.kv2_base_path}/+/client/{{identity.entity.metadata.acmevault_domain}}/pubkey" {
  capabilities = ["read"]
}
path "${var.kv2_base_path}/+/client/{{identity.entity.metadata.acmevault_domain}}/certificate" {
  capabilities = ["read"]
}
path "${var.kv2_base_path}/+/client/{{identity.entity.metadata.acmevault_domain}}/privatekey" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "acmevault_server" {
  name = "acmevault_server"

  policy = <<EOT
path "${var.kv2_base_path}/+/server/*" {
  capabilities = ["list", "create", "update", "read", "delete"]
}
path "${var.kv2_base_path}/+/client/+/pubkey" {
  capabilities = ["read", "list", "create", "update", "delete"]
}
path "${var.kv2_base_path}/+/client/+/certificate" {
  capabilities = ["read", "list", "create", "update", "delete"]
}
path "${var.kv2_base_path}/+/client/+/privatekey" {
  capabilities = ["create", "update", "delete"]
}
path "${var.aws_path}/creds/${vault_aws_secret_backend_role.acmevault.name}" {
  capabilities = ["read"]
}
EOT
}
