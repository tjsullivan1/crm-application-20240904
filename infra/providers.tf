terraform {
  required_version = ">= 1.1"
  
  backend "azurerm" {
    environment = "public"
  }

  required_providers {
    azurerm = {
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {

  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}