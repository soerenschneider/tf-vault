module "acmevault" {
  source      = "../../modules/app_acmevault"
  aws_path    = module.aws["default"].mount_path
  kv2_base_path = "${vault_mount.kv.path}/data/acmevault"
}


module "ansible" {
  source = "../../modules/app_ansible"
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
  environment = local.instance
}
