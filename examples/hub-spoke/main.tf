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

locals {
  networks = {
    hub   = { cidr = "10.40.0.0/16", subnet = "10.40.1.0/24" }
    spoke = { cidr = "10.50.0.0/16", subnet = "10.50.1.0/24" }
  }
  connections = {
    hub-to-spoke = { local = "hub", remote = "spoke" }
    spoke-to-hub = { local = "spoke", remote = "hub" }
  }
}

resource "azurerm_resource_group" "network" {
  for_each = local.networks
  name     = "rg-example-${each.key}"
  location = "uksouth"
}

module "network" {
  for_each = local.networks
  source   = "../.."

  name                = "vnet-example-${each.key}"
  resource_group_name = azurerm_resource_group.network[each.key].name
  location            = azurerm_resource_group.network[each.key].location
  address_space       = [each.value.cidr]
  subnets = {
    application = {
      address_prefixes       = [each.value.subnet]
      network_security_group = { name = "nsg-example-${each.key}-application" }
    }
  }
  tags = { Environment = "example", Role = each.key, ManagedBy = "Terraform" }
}

# Create both directions AFTER the VNets; module inputs have no cyclic dependency.
resource "azurerm_virtual_network_peering" "connection" {
  for_each = local.connections

  name                         = each.key
  resource_group_name          = azurerm_resource_group.network[each.value.local].name
  virtual_network_name         = module.network[each.value.local].vnet_name
  remote_virtual_network_id    = module.network[each.value.remote].vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
  triggers = {
    remote_address_space = local.networks[each.value.remote].cidr
  }
}

output "virtual_network_ids" {
  description = "Network IDs keyed by hub/spoke role."
  value       = { for role, network in module.network : role => network.vnet_id }
}
