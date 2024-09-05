resource "azurerm_service_plan" "plan" {
  name                = "${var.base_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type = "Windows"
  sku_name = "P0v3"
}

resource "azurerm_windows_web_app" "app" {
  name                = "${var.base_name}-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id = azurerm_service_plan.plan.id

  https_only = true

  public_network_access_enabled                  = false
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    vnet_route_all_enabled = true
    use_32_bit_worker      = false
    http2_enabled          = true
    always_on              = true
    ftps_state             = "Disabled"

    application_stack {
      current_stack = "dotnet"
      dotnet_version = "v8.0"
    }
  }

  // This is the wire-up to the outbound/egress subnet
  virtual_network_subnet_id = azurerm_subnet.apps.id
}

# resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
#   name                  = "${var.base_name}-dns-link"
#   resource_group_name   = azurerm_resource_group.rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.appservice_dns_zone.name
#   virtual_network_id    = azurerm_virtual_network.vnet.id
# }

# resource "azurerm_private_dns_a_record" "dns_a_record" {
#   name                = azurerm_windows_web_app.app.name
#   zone_name           = azurerm_private_dns_zone.appservice_dns_zone.name
#   resource_group_name = azurerm_resource_group.rg.name
#   ttl                 = 300
#   records             = [azurerm_windows_web_app.app.default_hostname]
# }