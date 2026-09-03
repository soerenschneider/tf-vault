###############################################################################
# Everything in this file is gated on var.enable_aws. With the flag off, no AWS
# credentials are needed and no aws_* objects appear in the plan.
###############################################################################

locals {
  aws_count = var.enable_aws ? 1 : 0
}

data "aws_caller_identity" "current" {
  count = local.aws_count
}

data "aws_partition" "current" {
  count = local.aws_count
}

###############################################################################
# KMS key
#
# The key policy grants the account root full control, which is what allows the
# IAM policies below to take effect. Without it, IAM permissions on the key are
# ignored.
###############################################################################

data "aws_iam_policy_document" "key" {
  count = local.aws_count

  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current[0].partition}:iam::${data.aws_caller_identity.current[0].account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "this" {
  count = local.aws_count

  description              = "${var.environment} symmetric encryption key"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  rotation_period_in_days  = 365
  deletion_window_in_days  = var.aws_deletion_window_in_days
  policy                   = data.aws_iam_policy_document.key[0].json

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  count = local.aws_count

  name          = "alias/${var.environment}"
  target_key_id = aws_kms_key.this[0].key_id
}

###############################################################################
# Encrypt-only policy
###############################################################################

data "aws_iam_policy_document" "encrypt" {
  count = local.aws_count

  statement {
    sid    = "EncryptWithKey"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptTo",
      "kms:DescribeKey",
    ]

    resources = [aws_kms_key.this[0].arn]
  }
}

resource "aws_iam_policy" "encrypt" {
  count = local.aws_count

  name        = "${var.environment}-kms-encrypt"
  description = "Encrypt data with the ${var.environment} KMS key"
  policy      = data.aws_iam_policy_document.encrypt[0].json

  tags = var.tags
}

###############################################################################
# Decrypt-only policy
###############################################################################

data "aws_iam_policy_document" "decrypt" {
  count = local.aws_count

  statement {
    sid    = "DecryptWithKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:ReEncryptFrom",
      "kms:DescribeKey",
    ]

    resources = [aws_kms_key.this[0].arn]
  }
}

resource "aws_iam_policy" "decrypt" {
  count = local.aws_count

  name        = "${var.environment}-kms-decrypt"
  description = "Decrypt data with the ${var.environment} KMS key"
  policy      = data.aws_iam_policy_document.decrypt[0].json

  tags = var.tags
}

###############################################################################
# IAM user that can decrypt
###############################################################################

resource "aws_iam_user" "decryptor" {
  count = local.aws_count

  name = "${var.environment}-decryptor"
  path = "/service/"

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "decryptor" {
  count = local.aws_count

  user       = aws_iam_user.decryptor[0].name
  policy_arn = aws_iam_policy.decrypt[0].arn
}

resource "aws_iam_access_key" "decryptor" {
  count = local.aws_count

  user = aws_iam_user.decryptor[0].name
}

###############################################################################
# Access key into KV v2
###############################################################################

resource "vault_kv_secret_v2" "aws_decryptor" {
  count = local.aws_count

  mount = var.kv_mount
  name  = var.aws_kv_secret_path

  delete_all_versions = false

  data_json = jsonencode({
    aws_access_key_id     = aws_iam_access_key.decryptor[0].id
    aws_secret_access_key = aws_iam_access_key.decryptor[0].secret
    aws_region            = var.aws_region
    iam_user_arn          = aws_iam_user.decryptor[0].arn
    kms_key_arn           = aws_kms_key.this[0].arn
    kms_key_alias         = aws_kms_alias.this[0].name
  })

  custom_metadata {
    max_versions = 5
    data = {
      managed_by = "terraform"
      purpose    = "decrypt-only credentials for ${var.environment} KMS key"
    }
  }
}