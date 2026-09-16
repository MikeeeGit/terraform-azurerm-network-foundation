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

module "hub" {
  source               = "../.."
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location
  location_abbreviated = "uks"
  environment          = "dev"
  label                = "example-dev-hub"
  vnet_ip_range        = "10.40.0.0/16"
  subnets              = [{ name = "shared", address_prefix = "10.40.1.0/24", security_group = "", endpoints = [] }]
}
module "spoke" {
  source               = "../.."
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location
  location_abbreviated = "uks"
  environment          = "dev"
  label                = "example-dev-spoke"
  vnet_ip_range        = "10.41.0.0/16"
  subnets              = [{ name = "application", address_prefix = "10.41.1.0/24", security_group = "", endpoints = [] }]
}
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "hub-to-spoke"
  resource_group_name          = azurerm_resource_group.example.name
  virtual_network_name         = module.hub.vnet.name
  remote_virtual_network_id    = module.spoke.vnet.id
  allow_virtual_network_access = true
}
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "spoke-to-hub"
  resource_group_name          = azurerm_resource_group.example.name
  virtual_network_name         = module.spoke.vnet.name
  remote_virtual_network_id    = module.hub.vnet.id
  allow_virtual_network_access = true
}
