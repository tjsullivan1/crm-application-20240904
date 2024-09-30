variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location
  
  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.base_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "appOutbound" {
  name                 = "app-outbound"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.12.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "delegation"

    service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.base_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type = "Windows"
  sku_name = "P0v3"
}

resource "azurerm_windows_web_app" "app01" {
  name                = "${var.base_name}-01-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  https_only = true

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

    virtual_application {
      virtual_path = "/"
      physical_path = "site\\wwwroot"
      preload = true
    }

    virtual_application {
      virtual_path = "/app01"
      physical_path = "site\\wwwroot"
      preload = true
    }
  }

  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  // This is the wire-up to the outbound/egress subnet
  virtual_network_subnet_id = azurerm_subnet.appOutbound.id
}

resource "azurerm_windows_web_app" "app02" {
  name                = "${var.base_name}-02-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  https_only = true

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

    virtual_application {
      virtual_path = "/"
      physical_path = "site\\wwwroot"
      preload = true

      virtual_directory {
        virtual_path = "/app02"
        physical_path = "site\\wwwroot"
      }
    }

    virtual_application {
      virtual_path = "/app02/test"
      physical_path = "site\\wwwroot"
      preload = true
    }
  }

  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  // This is the wire-up to the outbound/egress subnet
  virtual_network_subnet_id = azurerm_subnet.appOutbound.id
}

resource "azurerm_cdn_frontdoor_profile" "afd" {
  name                = "${var.base_name}-afd"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Premium_AzureFrontDoor"
}