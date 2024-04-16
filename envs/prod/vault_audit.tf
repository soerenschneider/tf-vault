resource "vault_audit" "file" {
  count = var.audit_file == null ? 0 : 1
  type  = "file"

  options = {
    file_path = var.audit_file
  }
}
