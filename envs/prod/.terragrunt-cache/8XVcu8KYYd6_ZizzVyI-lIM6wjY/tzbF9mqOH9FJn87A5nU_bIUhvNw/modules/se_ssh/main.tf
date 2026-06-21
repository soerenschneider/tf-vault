resource "vault_mount" "ssh" {
  type = "ssh"
  path = var.mount_path
}

resource "vault_ssh_secret_backend_ca" "ca" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "roles" {
  for_each = {
    for index, role in var.roles :
    role.name => role
  }

  name                    = each.key
  backend                 = vault_mount.ssh.path
  key_type                = each.value.key_type
  allow_user_certificates = !var.sign_host_certificates
  allow_host_certificates = var.sign_host_certificates
  ttl                     = each.value.ttl
  max_ttl                 = each.value.max_ttl
  cidr_list               = join(",", each.value.cidr_list)
  allowed_users           = join(",", each.value.allowed_users)
  default_user            = each.value.default_user
  algorithm_signer        = each.value.algorithm_signer
  default_extensions      = each.value.default_extensions
  allowed_extensions      = each.value.allowed_extensions
  allowed_domains         = join(",", each.value.allowed_domains)
  allow_bare_domains      = false
  allow_subdomains        = true

  allowed_user_key_config {
    type    = "rsa"
    lengths = [3072, 4096]
  }

  allowed_user_key_config {
    type    = "ed25519"
    lengths = [0]
  }
}

resource "vault_policy" "client_sign" {
  for_each = {
    for index, role in var.roles :
    role.name => role
  }
  name = "ssh_${var.identifier}_${each.value.name}"

  policy = <<EOT
path "${var.mount_path}/sign/${each.value.name}" {
  capabilities = ["update"]
}
EOT
}
