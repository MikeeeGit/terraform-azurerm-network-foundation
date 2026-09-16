# This module owns only the local side. The remote owner creates the reciprocal link.
resource "azurerm_virtual_network_peering" "this" {
  for_each = var.peerings

  name                         = each.key
  resource_group_name          = var.resource_group_name
  virtual_network_name         = module.vnet.name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
  triggers                     = each.value.triggers
}
