variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "home_ip" {
  type = string
  description = "The CIDR block for your home IP address. Likely ends with a /32"
  
}

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location

  
  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
  }
}

