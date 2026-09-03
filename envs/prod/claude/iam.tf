##############################################################################
# Permissions boundary for dynamically created IAM users
#
# A boundary caps the effective permissions of a principal regardless of what is
# attached to it. Two things make it worth having here:
#
#   1. Without the ProtectVaultOwnedIam deny, a credential carrying IAMFullAccess
#      can attach AdministratorAccess to itself, or create a fresh access key on
#      the engine's own IAM user and hold it forever.
#   2. Without RequireBoundaryOnNewPrincipals, the same credential can simply
#      create an unbounded user and start over.
#
# Note the boundary does not meaningfully constrain a role that is already
# PowerUserAccess + IAMFullAccess in any other respect - that combination is
# effectively AdministratorAccess. Treat such roles accordingly.
##############################################################################

data "aws_iam_policy_document" "dynamic_boundary" {
  statement {
    sid       = "AllowAllByDefault"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  statement {
    sid     = "ProtectVaultOwnedIam"
    effect  = "Deny"
    actions = ["iam:*"]
    resources = [
      "${local.iam_prefix}:user/vault/*",
      "${local.iam_prefix}:role/vault/*",
      "${local.iam_prefix}:policy/vault/*",
    ]
  }

  statement {
    sid    = "PreventBoundaryRemoval"
    effect = "Deny"
    actions = [
      "iam:DeleteUserPermissionsBoundary",
      "iam:DeleteRolePermissionsBoundary",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.boundary_restricts_principal_creation ? [1] : []

    content {
      sid    = "RequireBoundaryOnNewPrincipals"
      effect = "Deny"
      actions = [
        "iam:CreateUser",
        "iam:CreateRole",
        "iam:PutUserPermissionsBoundary",
        "iam:PutRolePermissionsBoundary",
      ]
      resources = ["*"]

      condition {
        test     = "StringNotEquals"
        variable = "iam:PermissionsBoundary"
        values   = [local.boundary_arn]
      }
    }
  }
}

resource "aws_iam_policy" "dynamic_boundary" {
  count = var.create_permissions_boundary && local.uses_iam_user ? 1 : 0

  name        = local.boundary_name
  path        = local.system_path
  description = "Permissions boundary for IAM users issued by the Vault AWS secrets engine '${var.identifier}'."
  policy      = data.aws_iam_policy_document.dynamic_boundary.json

  tags = merge(var.tags, { "vault-instance" = var.identifier })

  lifecycle {
    # Guard against the hand-built ARN in tf_locals.tf drifting from reality; the
    # boundary document references itself by that ARN.
    postcondition {
      condition     = self.arn == local.boundary_arn
      error_message = "Computed boundary ARN does not match the created policy. Check local.boundary_arn in locals.tf."
    }
  }
}

##############################################################################
# Permissions the secrets engine itself needs
##############################################################################

data "aws_iam_policy_document" "engine" {
  # ---- iam_user credential type -------------------------------------------

  dynamic "statement" {
    for_each = local.uses_iam_user ? [1] : []

    content {
      sid       = "CreateDynamicUsers"
      effect    = "Allow"
      actions   = ["iam:CreateUser"]
      resources = [local.dynamic_user_arn]

      # Kept in its own statement: iam:PermissionsBoundary is only present on
      # CreateUser and Put*PermissionsBoundary requests, so folding other actions
      # in here would deny them for want of the key.
      dynamic "condition" {
        for_each = local.enforce_boundary_on_create ? [1] : []

        content {
          test     = "StringEquals"
          variable = "iam:PermissionsBoundary"
          values   = local.allowed_boundary_arns
        }
      }
    }
  }

  dynamic "statement" {
    for_each = local.uses_iam_user ? [1] : []

    content {
      sid    = "ManageDynamicUsers"
      effect = "Allow"
      actions = [
        "iam:DeleteUser",
        "iam:GetUser",
        "iam:TagUser",
        "iam:UntagUser",
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:ListAccessKeys",
        "iam:PutUserPolicy",
        "iam:DeleteUserPolicy",
        "iam:ListUserPolicies",
        "iam:ListAttachedUserPolicies",
        "iam:ListGroupsForUser",
      ]
      resources = [local.dynamic_user_arn]
    }
  }

  # Restrict attachment to exactly the managed policies declared in var.roles.
  dynamic "statement" {
    for_each = length(local.attachable_policy_arns) > 0 ? [1] : []

    content {
      sid    = "AttachDeclaredPoliciesOnly"
      effect = "Allow"
      actions = [
        "iam:AttachUserPolicy",
        "iam:DetachUserPolicy",
      ]
      resources = [local.dynamic_user_arn]

      condition {
        test     = "ArnEquals"
        variable = "iam:PolicyARN"
        values   = local.attachable_policy_arns
      }
    }
  }

  # Group membership authorises against the group ARN, not the user ARN.
  dynamic "statement" {
    for_each = length(local.managed_group_arns) > 0 ? [1] : []

    content {
      sid    = "ManageDeclaredGroupMembership"
      effect = "Allow"
      actions = [
        "iam:AddUserToGroup",
        "iam:RemoveUserFromGroup",
      ]
      resources = local.managed_group_arns
    }
  }

  # ---- assumed_role credential type ---------------------------------------
  #
  # The target roles must also trust this principal. See engine_principal_arn.
  dynamic "statement" {
    for_each = length(local.assumable_role_arns) > 0 ? [1] : []

    content {
      sid    = "AssumeConfiguredRoles"
      effect = "Allow"
      actions = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      resources = local.assumable_role_arns
    }
  }

  # ---- federation_token / session_token -----------------------------------

  dynamic "statement" {
    for_each = local.uses_federation ? [1] : []

    content {
      sid       = "GetFederationToken"
      effect    = "Allow"
      actions   = ["sts:GetFederationToken"]
      resources = ["${local.sts_prefix}:federated-user/*"]
    }
  }

  dynamic "statement" {
    for_each = local.uses_session ? [1] : []

    content {
      sid       = "GetSessionToken"
      effect    = "Allow"
      actions   = ["sts:GetSessionToken"]
      resources = ["*"]
    }
  }

  # ---- optional self-rotation ---------------------------------------------

  dynamic "statement" {
    for_each = var.allow_root_rotation && var.create_iam_user ? [1] : []

    content {
      sid    = "RotateOwnAccessKey"
      effect = "Allow"
      actions = [
        "iam:GetUser",
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:ListAccessKeys",
      ]
      resources = [local.system_user_arn]
    }
  }
}

resource "aws_iam_policy" "engine" {
  name        = "${local.name_prefix}-engine"
  path        = local.system_path
  description = "Permissions for the Vault AWS secrets engine '${var.identifier}'."
  policy      = data.aws_iam_policy_document.engine.json

  tags = merge(var.tags, { "vault-instance" = var.identifier })
}

##############################################################################
# Engine identity
#
# Only created when Vault has no ambient AWS credentials. If Vault runs on EC2
# or EKS, set create_iam_user = false and attach aws_iam_policy.engine to the
# instance profile or IRSA role instead - that removes a long-lived secret from
# Terraform state entirely.
##############################################################################

#trivy:ignore:AVD-AWS-0143
resource "aws_iam_user" "engine" {
  #checkov:skip=CKV_AWS_273:System user for the Vault AWS secrets engine; not a human identity
  count = var.create_iam_user ? 1 : 0

  name          = local.name_prefix
  path          = local.system_path
  force_destroy = var.iam_user_force_destroy

  tags = merge(var.tags, { "vault-instance" = var.identifier })
}

resource "aws_iam_user_policy_attachment" "engine" {
  #checkov:skip=CKV_AWS_40:Exception for the Vault-managed system user
  count = var.create_iam_user ? 1 : 0

  user       = aws_iam_user.engine[0].name
  policy_arn = aws_iam_policy.engine.arn
}

resource "aws_iam_access_key" "engine" {
  count = var.create_iam_user ? 1 : 0

  user = aws_iam_user.engine[0].name
}
