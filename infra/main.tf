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
}

