terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.33.0, < 5.0.0"
    }
  }
}
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "example" {
  name     = "example-dev-network-rg"
  location = "uksouth"
}

module "network" {
  source               = "../.."
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location
  location_abbreviated = "uks"
  environment          = "dev"
  label                = "example-dev"
  vnet_ip_range        = "10.40.0.0/16"
  config_root          = "${path.module}/config"
  tags                 = { Environment = "dev", ManagedBy = "Terraform" }
  subnets = [{
    name                            = "application"
    address_prefix                  = "10.40.1.0/24"
    security_group                  = "enabled"
    endpoints                       = ["Microsoft.Storage"]
    default_outbound_access_enabled = false
  }]
}
output "vnet" { value = module.network.vnet }
output "subnet_ids" { value = module.network.subnet_ids }
