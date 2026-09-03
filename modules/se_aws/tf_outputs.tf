output "mount_path" {
  description = "Vault path the secrets engine is mounted at."
  value       = vault_aws_secret_backend.this.path
}

output "mount_accessor" {
  description = "Accessor of the mount, for use in templated policies and entity aliases."
  value       = vault_aws_secret_backend.this.accessor
}

output "role_names" {
  description = "Names of the roles created on the mount."
  value       = sort(keys(local.roles))
}

output "credential_paths" {
  description = "Map of role name to the Vault path that issues its credentials."
  value       = { for k, v in local.roles : k => "${local.mount_path}/creds/${k}" }
}

output "vault_policy_names" {
  description = "Map of role name to the Vault ACL policy granting access to it."
  value       = { for k, v in vault_policy.this : k => v.name }
}

output "engine_policy_arn" {
  description = "IAM policy carrying the permissions the engine needs. Attach this to Vault's own role when create_iam_user = false."
  value       = aws_iam_policy.engine.arn
}

output "engine_principal_arn" {
  description = "ARN of the principal the engine authenticates as. Add this to the trust policy of any role referenced by an assumed_role role."
  value       = var.create_iam_user ? aws_iam_user.engine[0].arn : null
}

output "permissions_boundary_arn" {
  description = "ARN of the permissions boundary applied to dynamically created IAM users, if one was created."
  value       = var.create_permissions_boundary && local.uses_iam_user ? aws_iam_policy.dynamic_boundary[0].arn : null
}

output "dynamic_user_path" {
  description = "IAM path dynamically created users are placed under. Unique to this module instance."
  value       = local.dynamic_path
}

output "dynamic_user_arn_pattern" {
  description = "ARN pattern matching every IAM user this instance can create. Useful for CloudTrail queries and SCPs."
  value       = local.dynamic_user_arn
}
