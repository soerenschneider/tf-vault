

output "policies" {
  description = "SOPS Transit policies by key."

  value = {
    encrypt = {
      for key, policy in vault_policy.transit_encrypt :
      key => policy.name
    }

    decrypt = {
      for key, policy in vault_policy.transit_decrypt :
      key => policy.name
    }

    encrypt_decrypt = {
      for key, policy in vault_policy.transit_encrypt_decrypt :
      key => policy.name
    }
  }
}

###############################################################################
# Vault transit
###############################################################################
output transit_mount {
  value = vault_mount.transit.path
}

output "transit_key_name" {
  value = vault_transit_secret_backend_key.key.name
}

###############################################################################
# AWS KMS — null when enable_aws = false
###############################################################################

output "kms_key_arn" {
  value = one(aws_kms_key.this[*].arn)
}

output "kms_key_alias" {
  value = one(aws_kms_alias.this[*].name)
}

output "kms_encrypt_policy_arn" {
  description = "Attach to whatever writes encrypted data."
  value       = one(aws_iam_policy.encrypt[*].arn)
}

output "kms_decrypt_policy_arn" {
  value = one(aws_iam_policy.decrypt[*].arn)
}

output "kms_decryptor_user_arn" {
  value = one(aws_iam_user.decryptor[*].arn)
}

output "aws_kv_secret_path" {
  value = var.enable_aws ? "${var.kv_mount}/data/${var.aws_kv_secret_path}" : null
}