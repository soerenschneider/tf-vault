output "prometheus_token" {
  sensitive = true
  value     = vault_token.prometheus.client_token
}
