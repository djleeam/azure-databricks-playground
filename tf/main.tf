locals {
  prefix = "databricks-sandbox-${random_string.naming.result}"
  tags = {
    Environment = "sandbox"
    Owner       = lookup(data.external.me.result, "name")
  }
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

data "azurerm_client_config" "current" {
}

data "external" "me" {
  program = ["az", "account", "show", "--query", "user"]
}

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

resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = var.region
  tags     = local.tags
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "${local.prefix}-workspace"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = "${local.prefix}-workspace-rg"
  tags                        = local.tags
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