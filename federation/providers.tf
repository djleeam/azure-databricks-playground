terraform {
  required_providers {
    azurerm = "~> 2.37"
    random  = "~> 2.2"
    databricks = {
      source = "databricks/databricks"
    }
  }
}

data "azurerm_client_config" "current" {}

provider "azurerm" {
  features {}
}

provider "databricks" {
  host = azurerm_databricks_workspace.this.workspace_url
}
