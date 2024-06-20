terraform {
  required_providers {
    azurerm = "~> 2.37"
    random  = "~> 2.2"
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

  }
}

provider "databricks" {
  host = azurerm_databricks_workspace.this.workspace_url
}
