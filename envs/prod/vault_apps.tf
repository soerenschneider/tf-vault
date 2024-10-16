module "acmevault" {
  source      = "../../modules/app_acmevault"
  aws_path    = module.aws["default"].path
  path_prefix = "${vault_mount.kv.path}/data/acmevault"
}


module "ansible" {
  source = "../../modules/app_ansible"
}

module "dyndns" {
  source                  = "../../modules/app_dyndns"
  aws_secret_backend_path = module.aws["default"].path
  route53_hosted_zone     = var.aws.route53_hosted_zone
}

module "occult" {
  source  = "../../modules/app_occult"
  kv_path = vault_mount.kv.path
}

module "vault_unsealer" {
  source = "../../modules/app_vault_unsealer"
}
