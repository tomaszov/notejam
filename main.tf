locals {
  env_variables = {
    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.nordcloudapps.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.nordcloudapps.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.nordcloudapps.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    WEBSITES_PORT                       = 3000
    
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

# Azure Container Regristry
resource "azurerm_container_registry" "nordcloudapps" {
  name                     = "nordcloudapps"
  resource_group_name      = "tf"
  location                 = "westeurope"
  sku                      = "Basic"
  admin_enabled            = true
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
  address_prefixes     = ["192.168.2.0/24"]
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
    linux_fx_version = "DOCKER|nordcloudapps.azurecr.io/notejam:latest"
    always_on        = "true"
  }
  lifecycle {
    ignore_changes = [
      site_config["scm_type"]
    ]
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = local.env_variables
}

resource "azurerm_monitor_autoscale_setting" "notejam_scaling" {
  name                = "notejam_autoscale"
  resource_group_name = azurerm_resource_group.nordcloud.name
  location            = azurerm_resource_group.nordcloud.location
  target_resource_id  = azurerm_app_service_plan.nordcloud_notejam.id
  profile {
    name = "default"
    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.nordcloud_notejam.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 90
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.nordcloud_notejam.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }  
}

module "mssql-server" {
  source  = "kumarvna/mssql-db/azurerm"
  version = "1.1.0"

  # By default, this module will not create a resource group
  # proivde a name to use an existing resource group, specify the existing resource group name,
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG. 
  resource_group_name  = "nordcloud"
  location             = "westeurope"
  virtual_network_name = "nordcloud-vnet"
  create_resource_group = false


  # SQL Server and Database details
  # The valid service objective name for the database include S0, S1, S2, S3, P1, P2, P4, P6, P11 
  sqlserver_name               = "notejamsql01"
  database_name                = "notejamsqldb"
  sql_database_edition         = "Standard"
  sqldb_service_objective_name = "S0"

  # SQL server extended auditing policy defaults to `true`. 
  # To turn off set enable_sql_server_extended_auditing_policy to `false`  
  # DB extended auditing policy defaults to `false`. 
  # to tun on set the variable `enable_database_extended_auditing_policy` to `true` 
  # To enable Azure Defender for database set `enable_threat_detection_policy` to true 
  enable_threat_detection_policy = true
  log_retention_days             = 30

  # schedule scan notifications to the subscription administrators
  # Manage Vulnerability Assessment set `enable_vulnerability_assessment` to `true`
  enable_vulnerability_assessment = false
  email_addresses_for_alerts      = ["user@example.com", "firstname.lastname@example.com"]

  # AD administrator for an Azure SQL server
  # Allows you to set a user or group as the AD administrator for an Azure SQL server
  ad_admin_login_name = "firstname.lastname@example.com"

  # (Optional) To enable Azure Monitoring for Azure SQL database including audit logs
  # log analytic workspace name required
  enable_log_monitoring        = false
  #log_analytics_workspace_name = "loganalytics_notejamsql"

  # Sql failover group creation. required secondary locaiton input. 
  enable_failover_group         = true
  secondary_sql_server_location = "northeurope"

  # Firewall Rules to allow azure and external clients and specific Ip address/ranges. 
  enable_firewall_rules = true
  firewall_rules = [
    {
      name             = "access-to-azure"
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  ]

  # Create and initialize a database with custom SQL script
  # need sqlcmd utility to run this command
  # your desktop public IP must be added firewall rules to run this command 
  initialize_sql_script_execution = false
  #sqldb_init_script_file          = "../artifacts/db-init-sample.sql"

  # Tags for Azure Resources
  tags = {
    Terraform   = "true"
    Environment = "prod"
    Owner       = "nordcloud"
  }
}
