provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "nordcloud"
    storage_account_name = "notejamtf"
    container_name       = "tfstatedevops"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "nordcloud" {
  name     = "nordcloud"
  location = "westeurope"
}

