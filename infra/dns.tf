resource "azurerm_private_dns_zone" "appservice_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name
}