resource "vault_policy" "emergency" {
  name = "emergency_seal"

  policy = <<EOT
path "/sys/seal" {
  capabilities = ["update", "sudo"]
}
EOT
}
