resource "vault_pki_secret_backend_role" "role" {
  for_each                 = { for role in var.backend_roles : role.name => role }
  backend                  = vault_mount.pki_intermediate.path
  name                     = each.value.name
  ttl                      = each.value.ttl
  max_ttl                  = each.value.max_ttl
  allow_ip_sans            = true
  key_type                 = each.value.key_type
  key_bits                 = each.value.key_bits
  allowed_domains          = each.value.allowed_domains
  allowed_domains_template = each.value.allowed_domains_template
  allow_subdomains         = each.value.allow_subdomains
  allow_bare_domains       = each.value.allow_bare_domains
}
