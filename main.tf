terraform {
  required_providers {
    sql = {
      source  = "paultyng/sql"
      version = "0.5.0"
    }
  }
}

provider "sql" {
  alias = "mysql"
  url   = "mysql://root:kodejifr@tcp(172.17.0.1:3306)/mysql"
}

resource "sql_migrate" "create_db" {
  for_each = local.databases

  migration {
    id   = "db-${each.key}"
    up   = "CREATE DATABASE ${each.key};"
    down = "DROP DATABASE IF EXISTS ${each.key};"
  }

  provider = sql.mysql
}

resource "sql_migrate" "create_user" {
  for_each = local.users

  migration {
    id   = "user-${each.key}"
    up   = "CREATE USER IF NOT EXISTS '${each.key}' IDENTIFIED BY 'teste';"
    down = "DROP USER IF EXISTS '${each.key}'@'%';"
  }

  depends_on = [sql_migrate.create_db]

  provider = sql.mysql
}

resource "sql_migrate" "create_user_permission" {
  for_each = local.users

  migration {
    id   = "user-${each.key}"
    up   = "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, PROCESS, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, CREATE VIEW, EVENT, TRIGGER, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON *.* TO '${each.key}'@'%';"
    down = "DROP USER IF EXISTS '${each.key}'@'%';"
  }

  depends_on = [sql_migrate.create_user]

  provider = sql.mysql
}

data "sql_query" "flush_privileges" {
  query = "FLUSH PRIVILEGES;"

  depends_on = [sql_migrate.create_user_permission]

  provider = sql.mysql
}

locals {
  databases = {
    "tenant_manager" = {}
  }

  users = {
    "tenant_manager" = {}
    "felipe"         = {}
  }

  permissions = {
    "admin" = ""
    "read"  = ""
  }
}
