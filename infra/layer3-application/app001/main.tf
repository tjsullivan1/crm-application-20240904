variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "user_managed_identity" {
  type        = string
  description = "The principal or application ID of the Azure user managed identity to assign to the resources."
}

variable "outbound_subnet_id" {
  type        = string
  description = "The id of the subnet that the app services will use to communicate with other services."
}

variable "key_vault_uri" {
  type        = string
  description = "The URI to the key vault where app service secretes are stored."
}

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location
  
  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
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

  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  // This is the wire-up to the outbound/egress subnet
  virtual_network_subnet_id = var.outbound_subnet_id

  // This is the user that will be use to access the key vault secrets
  key_vault_reference_identity_id = var.user_managed_identity

  // Setup the app service with a user assigned identity
  identity {
    type = "UserAssigned"
    identity_ids = [var.user_managed_identity]
  }

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

  app_settings = {
    "MY_SETTING" = "Something Special!"
    "MY_SECRET"  = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/TestSecret)"
  }
}

resource "azurerm_windows_web_app" "app02" {
  name                = "${var.base_name}-02-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  https_only = true

  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  // This is the wire-up to the outbound/egress subnet
  virtual_network_subnet_id = var.outbound_subnet_id

  // This is the user that will be use to access the key vault secrets
  key_vault_reference_identity_id = var.user_managed_identity

  // Setup the app service with a user assigned identity
  identity {
    type = "UserAssigned"
    identity_ids = [var.user_managed_identity]
  }

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
}