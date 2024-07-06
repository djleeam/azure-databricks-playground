# Synapse Datalake Storage Account
resource "azurerm_storage_account" "synapse_datalake" {
  name                      = "synapse01${random_string.naming.result}"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  account_kind              = "StorageV2"
  is_hns_enabled            = "true"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

# Synapse Datalake File System
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_datalake_fs" {
  name               = "synapse${random_string.naming.result}"
  storage_account_id = azurerm_storage_account.synapse_datalake.id
  depends_on         = [azurerm_storage_account.synapse_datalake]
}

# Synapse SQL Password
resource "random_password" "synapse_sql_password" {
  length      = 32
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_key_vault_secret" "synapse_sql_password" {
  name         = "synapse01-password"
  value        = random_password.synapse_sql_password.result
  key_vault_id = azurerm_key_vault.sandbox.id
  content_type = "Terraform"
}

# Synapse Workspace
resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                                 = "synapse01${random_string.naming.result}"
  location                             = azurerm_resource_group.this.location
  resource_group_name                  = azurerm_resource_group.this.name
  sql_administrator_login              = "synapseAdmin"
  sql_administrator_login_password     = random_password.synapse_sql_password.result
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_datalake_fs.id

  depends_on = [azurerm_key_vault_secret.synapse_sql_password]
}

data "http" "myip" {
  url = "http://ifconfig.me"
}

# Synapse Workspace Firewall Rules
resource "azurerm_synapse_firewall_rule" "sandbox" {
  name                 = "my-ip-firewall-rule1"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id
  start_ip_address     = chomp(data.http.myip.response_body)
  end_ip_address       = chomp(data.http.myip.response_body)
}
