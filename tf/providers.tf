terraform {
  required_providers {
    azurerm = "~> 2.33"
    random  = "~> 2.2"
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "databricks" {
  host = azurerm_databricks_workspace.this.workspace_url
}