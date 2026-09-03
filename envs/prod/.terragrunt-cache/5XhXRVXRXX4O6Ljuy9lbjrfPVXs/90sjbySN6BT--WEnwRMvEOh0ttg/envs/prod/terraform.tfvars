users = [
  {
    name = "soeren"
  },
  {
    name              = "admin"
    token_ttl         = 900
    token_max_ttl     = 1200
    token_bound_cidrs = [
      "192.168.2.0/24",
      "192.168.64.0/24",
      "192.168.68.0/24",
      "192.168.72.0/24"
    ]
  }
]

identities = {
  admin = {
    policies = ["admin"]
  },
  soeren = {
    policies = [
      "aws_default_developer",
      "pki_human",
      "users",
      "transit_unsealer_prod_default_encrypt",
    ]
    metadata = {
      x509_cn = "user-soeren@soeren.cloud"
      ssh_principal = "soeren"
    }
  }
}

secret_engines_ssh = {
  servers = {
    sign_host_certificates = true
    mount_path             = "ssh/servers"
    roles = [
      {
        name            = "server"
        cidr_list       = ["192.168.0.0/16"]
        allowed_domains = ["soeren.cloud"]
        ttl             = 2592000
        max_ttl         = 7776000
      }
    ]
  }

  clients = {
    sign_host_certificates = false
    mount_path             = "ssh/clients"
    roles = [
      {
        name          = "ansible"
        cidr_list     = [
          "192.168.65.0/24"
        ]
        allowed_users = ["ansible"]
      },
      {
        name = "users"
        cidr_list = [
          "192.168.64.0/24",
          "192.168.2.0/24",
          "192.168.72.0/24",
          "192.168.200.100/30"
        ]
        allowed_users = ["{{identity.entity.metadata.ssh_principal}}"]
        allowed_users_template = true
        default_users  = "{{identity.entity.metadata.ssh_principal}}"
        default_users_template  = true
        default_extensions = {
          permit-pty = ""
        }
      }
    ]
  }
}

internal_pkis = {
  general = {
    pki_cert_domain       = "soeren.cloud"
    pki_root_common_name  = "srn.im root ca"
    pki_root_organization = "sorg"
    pki_root_mount        = "pki/root_srn"
    pki_im_common_name    = "srn.im intermediate ca"
    pki_im_organization   = "srn.imperium"
    pki_im_ou             = "sorg"
    pki_im_mount          = "pki/im_srn"
    pki_backend_roles = [
      {
        name               = "machine"
        allowed_domains    = ["{{identity.entity.metadata.host}}"]
        ttl                = 7776000
        max_ttl            = 7776000
        key_bits           = 3072
        allow_bare_domains = true
        allow_subdomains   = false
      },
      {
        name               = "enclave"
        allowed_domains    = ["{{identity.entity.metadata.host}}"]
        ttl                = 604800
        max_ttl            = 604800
        key_bits           = 2048
        allow_bare_domains = true
        allow_subdomains   = false
      },
      {
        name               = "certmanager"
        allowed_domains    = ["prometheus.svc.soeren.cloud"]
        ttl                = 7776000
        max_ttl            = 7776000
        key_bits           = 2048
        allow_bare_domains = true
        allow_subdomains   = false
      },
      {
        name = "rabbitmq"
        allowed_domains = [
          "rabbitmq.svc.soeren.cloud",
          "rabbitmq.svc.dd.soeren.cloud",
          "rabbitmq.svc.ez.soeren.cloud",
          "rabbitmq.svc.pt.soeren.cloud"
        ]
        ttl                = 7776000
        max_ttl            = 7776000
        key_bits           = 3072
        allow_bare_domains = true
        allow_subdomains   = false
      },
      {
        name = "mariadb"
        allowed_domains = [
          "mariadb.svc.soeren.cloud",
          "mariadb.svc.dd.soeren.cloud",
          "mariadb.svc.ez.soeren.cloud",
          "mariadb.svc.pt.soeren.cloud"
        ]
        ttl                = 7776000
        max_ttl            = 7776000
        key_bits           = 3072
        allow_bare_domains = true
        allow_subdomains   = false
      },
      {
        name               = "human"
        allowed_domains    = ["{{identity.entity.metadata.x509_cn}}"]
        ttl                = 28800
        max_ttl            = 28800
        key_bits           = 2048
        allow_bare_domains = true
        allow_subdomains   = false
      }
    ]
  }
}
