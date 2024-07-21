########################################
# Create a Virtual Network and Subnets
########################################

resource "azurerm_virtual_network" "databricks_vnet" {
  name                = "databricks-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "databricks-public-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.databricks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "databricks-delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "databricks-private-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.databricks_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "databricks-delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

#########################
# Create a NAT Gateway
#########################

/*
    The resource 'Microsoft.Network/publicIPAddresses/databricks-nat-gateway-ip' does not support availability zones at location 'westus'.
    If you want to use Availability Zones in the future, you might consider using a region that supports them for Public IP addresses. Some examples include:
        East US (eastus)
        East US 2 (eastus2)
        West US 2 (westus2)
        West US 3 (westus3)
        Central US (centralus)
*/

resource "azurerm_public_ip" "nat_gateway_ip" {
  name                = "databricks-nat-gateway-ip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "databricks_nat" {
  name                    = "databricks-nat-gateway"
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "nat_public_ip" {
  nat_gateway_id       = azurerm_nat_gateway.databricks_nat.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

##########################################################
# Associate the NAT Gateway with the Databricks subnets
##########################################################

resource "azurerm_subnet_nat_gateway_association" "public_subnet" {
  subnet_id      = azurerm_subnet.public_subnet.id
  nat_gateway_id = azurerm_nat_gateway.databricks_nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private_subnet" {
  subnet_id      = azurerm_subnet.private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.databricks_nat.id
}

##########################################################
# Create subnet network security groups
##########################################################

resource "azurerm_network_security_group" "public_subnet_nsg" {
  name                = "databricks-public-subnet-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "private_subnet_nsg" {
  name                = "databricks-private-subnet-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

##########################################################
# Associate subnets with network security groups
##########################################################

resource "azurerm_subnet_network_security_group_association" "public_subnet" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.public_subnet_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_subnet" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.private_subnet_nsg.id
}
