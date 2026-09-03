###############################################################################
# Shared
###############################################################################

variable "environment" {
  description = "Base name used for the transit key, Vault policies, IAM objects and AppRole."
  type        = string
  default     = "prod"
}

variable "kv_mount" {
  description = "Path where the Vault KV v2 secrets engine is mounted."
  type        = string
  default     = "secret"
}

variable "tags" {
  description = "Tags applied to all taggable AWS resources. Ignored when enable_aws = false."
  type        = map(string)
  default     = {}
}

variable "keys" {
  type    = set(string)
  default = []
}

variable "ttl_seconds" {
  type    = number
  default = 1800
}

variable "deletion_allowed" {
  type    = bool
  default = true
}

variable "ttl_max_seconds" {
  type    = number
  default = 3600
}


###############################################################################
# AWS KMS (optional)
###############################################################################

variable "enable_aws" {
  description = "Create the AWS KMS key, IAM policies, IAM user and its KV v2 secret."
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for the KMS key. Only used when enable_aws = true."
  type        = string
  default     = "eu-central-1"
}

variable "aws_deletion_window_in_days" {
  description = "Waiting period before a scheduled KMS key deletion completes."
  type        = number
  default     = 5
}

variable "aws_kv_secret_path" {
  description = "KV v2 path (without mount prefix) for the IAM decryptor's access key."
  type        = string
  default     = null
}