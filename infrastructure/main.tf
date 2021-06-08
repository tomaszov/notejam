locals {
  env_variables = {
    DOCKER_REGISTRY_SERVER_URL          = "https://nordcloudapps.azurecr.io"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tf"
    storage_account_name = "notejamtf"
    container_name       = "tfstatedevops"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "nordcloud" {
  name     = "nordcloud"
  location = "westeurope"
}

#Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "nordcloud-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.nordcloud.name
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.nordcloud.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}

resource "azurerm_app_service_plan" "nordcloud_notejam" {
  name                = "nordcloud_notejam"
  location            = azurerm_resource_group.nordcloud.location
  resource_group_name = azurerm_resource_group.nordcloud.name
  kind                = "Linux"
  sku {
    tier = "Basic"
    size = "B1"
  }

  reserved = true

}

resource "azurerm_app_service" "notejam" {
  name                    = "notejam"
  location                = azurerm_resource_group.nordcloud.location
  resource_group_name     = azurerm_resource_group.nordcloud.name
  app_service_plan_id     = azurerm_app_service_plan.nordcloud_notejam.id
  client_affinity_enabled = true
  source_control {
    repo_url = "https://github.com/tomaszov/notejam"
    branch = "main"
  }
  site_config {
    scm_type = "GitHub"
    linux_fx_version = "DOCKER|nordcloudapps/notejam:latest"
    always_on        = "true"
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = local.env_variables
}

