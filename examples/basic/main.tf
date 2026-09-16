terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
  }
}
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "example" {
  name     = "rg-network-example"
  location = "uksouth"
}
module "network" {
  source = "../.."

  name                = "vnet-network-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.40.0.0/16"]
  subnets = {
    application = {
      address_prefixes       = ["10.40.1.0/24"]
      network_security_group = { name = "nsg-application-example" }
    }
  }
  tags = { Project = "network-example", ManagedBy = "Terraform" }
}
output "subnet_ids" {
  value = module.network.subnet_ids
}
