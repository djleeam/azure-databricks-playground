locals {
  databricks_managed_rg_name = "liem-databricks-workspace-1-rg"
}

resource "azurerm_resource_group" "this" {
  name     = "liem.truong.1-rg"
  location = "westus2"
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "liem-databricks-workspace-1"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = local.databricks_managed_rg_name

  # Create a Databricks workspace with VNet injection and no public IP.
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.databricks_vnet.id
    public_subnet_name                                   = azurerm_subnet.public_subnet.name
    private_subnet_name                                  = azurerm_subnet.private_subnet.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public_subnet.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private_subnet.id
  }
}
