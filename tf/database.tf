data "external" "account_info" {
  program = [
    "az",
    "ad",
    "signed-in-user",
    "show",
    "--query",
    "{object_id:id}",
    "-o",
    "json",
  ]
}

data "http" "myip" {
  url = "http://ifconfig.me"
}

resource "azurerm_key_vault" "sandbox" {
  name                        = "sandbox-${random_string.naming.result}"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false


  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    # object_id = data.azurerm_client_config.current.object_id
    ## workaround: https://github.com/hashicorp/terraform-provider-azurerm/issues/16982
    object_id = data.external.account_info.result.object_id

    key_permissions = [
      "get",
      "list",
      "create",
      "update",
      "import",
      "delete",
      "backup",
      "restore",
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
      "backup",
      "restore",
    ]
  }

  tags = {
    environment = "sandbox"
  }
}

resource "random_password" "sandbox_sql_admin_password" {
  length           = 20
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "sandbox_sql_admin_password" {
  name         = "sandbox-sql-admin-password"
  value        = random_password.sandbox_sql_admin_password.result
  key_vault_id = azurerm_key_vault.sandbox.id
}

resource "azurerm_mssql_server" "sandbox" {
  name                         = "sandbox-sql-server-${random_string.naming.result}"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  minimum_tls_version          = "1.2"
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = azurerm_key_vault_secret.sandbox_sql_admin_password.value
}

resource "azurerm_mssql_firewall_rule" "sandbox" {
  name             = "my-ip-firewall-rule1"
  server_id        = azurerm_mssql_server.sandbox.id
  start_ip_address = chomp(data.http.myip.response_body)
  end_ip_address   = chomp(data.http.myip.response_body)
}

resource "azurerm_mssql_database" "sandbox" {
  name      = "sandbox-sql-db"
  server_id = azurerm_mssql_server.sandbox.id
}

resource "azurerm_storage_account" "sandbox" {
  name                     = "sandbox${random_string.naming.result}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "sandbox"
  }
}

# Enable change data capture
resource "azurerm_mssql_server_extended_auditing_policy" "sandbox" {
  server_id                               = azurerm_mssql_server.sandbox.id
  storage_endpoint                        = azurerm_storage_account.sandbox.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.sandbox.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 6
}

resource "azurerm_storage_container" "sandbox" {
  name                  = "sandbox-container"
  storage_account_name  = azurerm_storage_account.sandbox.name
  container_access_type = "private"
}
