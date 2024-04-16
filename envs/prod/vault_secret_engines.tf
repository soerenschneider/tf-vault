module "aws" {
  for_each = var.se_aws

  source         = "../../modules/se_aws"
  mount_path     = each.value.path
  identifier     = each.key
  aws_account_id = each.value.account_id
  roles          = each.value.roles
}

module "dbs" {
  source      = "../../modules/se_database"
  mariadb_dbs = var.db_mariadb_dbs
  mount_path  = "dbs"
}

module "se_k8s" {
  source              = "../../modules/se_kubernetes"
  for_each            = var.secret_engines_k8s
  mount_path          = each.value.mount_path
  identifier          = each.value.name
  host                = each.value.host
  ca_cert             = each.value.ca_cert != null ? each.value.ca_cert : file(each.value.ca_cert_file)
  service_account_jwt = each.value.service_account_jwt
  roles               = each.value.roles
}

resource "vault_mount" "kv" {
  path        = var.kv2_mount
  type        = "kv-v2"
  description = "Secret kv mount"
}

module "pki" {
  source = "../../modules/se_pki_internal_ca"
  for_each = {
    for key, val in var.internal_pkis : key => val
  }

  server_url  = "https://vault.ha.soeren.cloud"
  cert_domain = each.value.pki_cert_domain

  pki_name          = each.key
  root_common_name  = each.value.pki_root_common_name
  root_organization = each.value.pki_root_organization
  root_mount_path   = each.value.pki_root_mount

  intermediate_mount_max_ttl = local.default_1mo_in_sec
  intermediate_common_name   = each.value.pki_im_common_name
  intermediate_organization  = each.value.pki_im_organization
  intermediate_ou            = each.value.pki_im_ou
  intermediate_mount_path    = each.value.pki_im_mount

  backend_roles = each.value.pki_backend_roles
}

module "sops_transit_kubernetes" {
  source       = "../../modules/app_sops_transit"
  name         = "kubernetes"
  environments = toset(["svc-ez", "svc-dd", "svc-pt"])
}

resource "vault_policy" "pki_boyscout" {
  name = "pki_boyscout"

  policy = <<EOT
path "pki_im_srn/revoke" {
  capabilities = ["update"]
}

path "pki_im_task/tidy" {
  capabilities = ["update"]
}
EOT
}

module "se_ssh" {
  for_each = var.secret_engines_ssh

  source                 = "../../modules/se_ssh"
  identifier             = each.key
  sign_host_certificates = each.value.sign_host_certificates
  mount_path             = each.value.mount_path
  roles                  = each.value.roles
}
