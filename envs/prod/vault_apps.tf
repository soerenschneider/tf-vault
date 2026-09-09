module "acmevault" {
  source      = "../../modules/app_acmevault"
  aws_path    = module.aws["default"].mount_path
  kv2_base_path = "${vault_mount.kv.path}/data/acmevault"
  environment = local.environment
}

# module "dyndns" {
#   source                  = "../../modules/app_dyndns"
#   aws_secret_backend_path = module.aws["default"].path
#   route53_hosted_zone     = var.aws.route53_hosted_zone
# }

module "sops_ansible" {
  source  = "../../modules/app_sops_transit"
  name    = "ansible"
}

module "vault_unsealer" {
  source = "../../modules/app_vault_unsealer"
  environment = local.environment
  enable_aws = true
  kv_mount = var.kv2_mount
  aws_permissions_boundary_arn = module.aws["default"].permissions_boundary_arn
  aws_kv_secret_path = "soeren.cloud/env/prod/vault-unsealer"
}
