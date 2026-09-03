resource "vault_mount" "ssh" {
  type = "ssh"
  path = var.mount_path
}

resource "vault_ssh_secret_backend_ca" "ca" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}

locals {
  # cidr_list is silently ignored by Vault for key_type = "ca". For user
  # certificates the equivalent is the source-address critical option, which
  # sshd enforces. Host certificates have no equivalent, so it's dropped.
  roles = {
    for role in var.roles : role.name => merge(role, {
      cidr_list = role.key_type == "ca" || length(role.cidr_list) == 0 ? null : join(",", role.cidr_list)

      default_critical_options = merge(
          role.key_type == "ca" && !var.sign_host_certificates && length(role.cidr_list) > 0
          ? { "source-address" = join(",", role.cidr_list) }
          : {},
        role.default_critical_options, # an explicit value always wins
      )
    })
  }
}

resource "vault_ssh_secret_backend_role" "roles" {
  for_each = local.roles

  name                    = each.key
  backend                 = vault_mount.ssh.path
  key_type                = each.value.key_type
  allow_user_certificates = !var.sign_host_certificates
  allow_host_certificates = var.sign_host_certificates
  ttl                     = each.value.ttl
  max_ttl                 = each.value.max_ttl
  cidr_list               = each.value.cidr_list
  allowed_users           = join(",", each.value.allowed_users)
  allowed_users_template  = each.value.allowed_users_template
  default_user            = each.value.default_user
  default_user_template   = each.value.default_user_template
  algorithm_signer        = each.value.algorithm_signer
  default_extensions      = each.value.default_extensions
  allowed_extensions      = each.value.allowed_extensions
  allowed_domains         = join(",", each.value.allowed_domains)
  allow_bare_domains      = false
  allow_subdomains        = true

  default_critical_options = each.value.default_critical_options
  allowed_critical_options = each.value.allowed_critical_options

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
