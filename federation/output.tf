output "databricks_nat_gateway_ip" {
  value = azurerm_public_ip.nat_gateway_ip.ip_address
}
