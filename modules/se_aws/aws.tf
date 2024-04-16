resource "vault_aws_secret_backend" "aws" {
  path                      = var.mount_path
  access_key                = aws_iam_access_key.vault.id
  secret_key                = aws_iam_access_key.vault.secret
  region                    = var.region
  max_lease_ttl_seconds     = var.max_lease_ttl
  default_lease_ttl_seconds = var.default_lease_ttl
}

#trivy:ignore:AVD-AWS-0143
resource "aws_iam_user" "vault" {
  #checkov:skip=CKV_AWS_273:This is a system user created solely for Vault
  name = "vault-${var.identifier}"
  path = "/system/"
}

resource "aws_iam_access_key" "vault" {
  user = aws_iam_user.vault.name
}

resource "vault_aws_secret_backend_role" "roles" {
  for_each = {
    for index, role in var.roles : role.name => role
  }

  backend         = vault_aws_secret_backend.aws.path
  name            = each.value.name
  credential_type = each.value.credential_type
  role_arns       = each.value.role_arns
  policy_arns     = each.value.policy_arns
  policy_document = each.value.policy_document
}

resource "vault_policy" "roles" {
  for_each = {
    for index, role in var.roles : role.name => role
  }

  name   = "aws_${var.identifier}_${each.value.name}"
  policy = <<EOT
path "${vault_aws_secret_backend.aws.path}/creds/${each.value.name}"
{
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "powerusers" {
  for_each = {
    for index, role in var.roles : role.name => role
  }

  name   = "aws_${var.identifier}_poweruser"
  policy = <<EOT
path "${vault_aws_secret_backend.aws.path}/creds/*"
{
  capabilities = ["read"]
}
EOT
}
