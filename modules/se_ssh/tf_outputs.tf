output "mount_path" {
  description = "Vault path the secrets engine is mounted at."
  value       = vault_mount.ssh.path
}
