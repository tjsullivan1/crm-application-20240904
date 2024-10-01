variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location
  
  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${var.base_name}-wksp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_user_assigned_identity" "user_identity" {
  name                = "${var.base_name}-id"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_key_vault" "kv" {
  name                = "${var.base_name}-kv"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true
}

# Make the current Terraform user (whoever is runnign this script) a Key Vault Administrator so they can create secrets
resource "azurerm_role_assignment" "kv_admin_role" {
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.kv.id
  principal_id         = data.azurerm_client_config.current.object_id
}

# Add an assignment so the User Assigned Identity can read secrets
resource "azurerm_role_assignment" "kv_user_role" {
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.kv.id
  principal_id         = azurerm_user_assigned_identity.user_identity.principal_id
}

# Add a dummy secret for testing purposes
resource "azurerm_key_vault_secret" "secret" {
  key_vault_id = azurerm_key_vault.kv.id
  name = "TestSecret"
  value = "Top Secret Value!"
}