resource "vault_aws_secret_backend" "this" {
  path        = local.mount_path
  description = coalesce(var.description, "AWS dynamic credentials (${var.identifier})")
  region      = var.region

  access_key = var.create_iam_user ? aws_iam_access_key.engine[0].id : null
  secret_key = var.create_iam_user ? aws_iam_access_key.engine[0].secret : null

  default_lease_ttl_seconds = var.default_lease_ttl
  max_lease_ttl_seconds     = var.max_lease_ttl
  username_template         = var.username_template

  # Preserve mount data if the path is ever changed rather than tearing down and
  # orphaning every outstanding lease.
  disable_remount = false

  depends_on = [aws_iam_user_policy_attachment.engine]

  lifecycle {
    precondition {
      condition     = var.default_lease_ttl <= var.max_lease_ttl
      error_message = "default_lease_ttl (${var.default_lease_ttl}) must not exceed max_lease_ttl (${var.max_lease_ttl})."
    }
  }
}

resource "vault_aws_secret_backend_role" "this" {
  for_each = local.roles

  backend         = vault_aws_secret_backend.this.path
  name            = each.key
  credential_type = each.value.credential_type

  policy_arns     = each.value.policy_arns
  policy_document = each.value.policy_document
  role_arns       = each.value.role_arns
  iam_groups      = each.value.iam_groups

  # user_path is the mechanism that keeps concurrent instances of this module
  # isolated: it places dynamic users inside this instance's IAM namespace, which
  # is the only namespace aws_iam_policy.engine grants access to.
  user_path = each.value.credential_type == "iam_user" ? local.dynamic_path : null

  permissions_boundary_arn = (
    each.value.credential_type == "iam_user"
    ? lookup(local.role_boundary_arn, each.key, null)
    : null
  )

  iam_tags = (
    each.value.credential_type == "iam_user"
    ? merge(
      var.dynamic_user_tags,
      { "vault-instance" = var.identifier, "vault-role" = each.key },
      coalesce(each.value.iam_tags, {}),
    )
    : null
  )

  default_sts_ttl = each.value.default_sts_ttl
  max_sts_ttl     = each.value.max_sts_ttl

  depends_on = [aws_iam_policy.dynamic_boundary]
}

resource "vault_policy" "this" {
  for_each = var.manage_vault_policies ? local.roles : {}

  name = coalesce(each.value.vault_policy_name, "${local.policy_name_prefix}${each.key}")

  # "update" alongside "read" so callers can pass parameters such as ttl or
  # role_arn, which requires a POST rather than a GET.
  policy = join("\n", concat(
    [
      <<-EOT
        # Issue dynamic AWS credentials for the "${each.key}" role.
        path "${local.mount_path}/creds/${each.key}" {
          capabilities = ["read", "update"]
        }
      EOT
    ],
    each.value.credential_type == "assumed_role" ? [
      <<-EOT
        # STS alias for the same role.
        path "${local.mount_path}/sts/${each.key}" {
          capabilities = ["read", "update"]
        }
      EOT
    ] : [],
  ))
}
