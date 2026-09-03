locals {
  mysql_roles = flatten([
    for index, dbs in var.mariadb_dbs : [
      for role in dbs.roles : [
        {
          db                  = index
          db_name             = dbs.name
          name                = role.name,
          creation_statements = role.creation_statements
          default_ttl         = role.default_ttl
          max_ttl             = role.max_ttl
        }
      ]
    ]
  ])

  postgres_roles = flatten([
    for index, dbs in var.postgres_dbs : [
      for role in dbs.roles : [
        {
          db                  = index
          db_name             = dbs.name
          name                = role.name,
          creation_statements = role.creation_statements
          default_ttl         = role.default_ttl
          max_ttl             = role.max_ttl
        }
      ]
    ]
  ])
}

resource "vault_database_secrets_mount" "db" {
  path = var.mount_path

  dynamic "mysql" {
    for_each = {
      for index, val in var.mariadb_dbs : val.name => val
    }
    content {
      name           = mysql.value.name
      username       = mysql.value.username
      password       = mysql.value.password
      connection_url = mysql.value.connection_url
      allowed_roles = [
        for role in mysql.value.roles : role.name
      ]
    }
  }

  dynamic "postgresql" {
    for_each = {
      for index, val in var.postgres_dbs : val.name => val
    }
    content {
      name           = postgresql.value.name
      username       = postgresql.value.username
      password       = postgresql.value.password
      connection_url = postgresql.value.connection_url
      allowed_roles = [
        for role in postgresql.value.roles : role.name
      ]
    }
  }
}

resource "vault_database_secret_backend_role" "mysql" {
  for_each = {
    for k, v in local.mysql_roles : k => v
  }

  name                = each.value.name
  backend             = vault_database_secrets_mount.db.path
  db_name             = vault_database_secrets_mount.db.mysql[each.value.db].name
  default_ttl         = each.value.default_ttl
  max_ttl             = each.value.max_ttl
  creation_statements = each.value.creation_statements
}

resource "vault_database_secret_backend_role" "postgresl" {
  for_each = {
    for k, v in local.postgres_roles : k => v
  }

  name                = each.value.name
  backend             = vault_database_secrets_mount.db.path
  db_name             = vault_database_secrets_mount.db.postgresql[each.value.db].name
  default_ttl         = each.value.default_ttl
  max_ttl             = each.value.max_ttl
  creation_statements = each.value.creation_statements
}

resource "vault_policy" "mysql" {
  for_each = {
    for k, v in local.mysql_roles : k => v
  }
  name = "dbs_mysql_${each.value.name}"

  policy = <<EOT
path "${var.mount_path}/creds/${each.value.name}" {
  capabilities = ["update"]
}
EOT
}

resource "vault_policy" "postgres" {
  for_each = {
    for k, v in local.postgres_roles : k => v
  }
  name = "dbs_postgres_${each.value.name}"

  policy = <<EOT
path "${var.mount_path}/creds/${each.value.name}" {
  capabilities = ["update"]
}
EOT
}
