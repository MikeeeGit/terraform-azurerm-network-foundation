output "vnet_id" {
  description = "Virtual network resource ID."
  value       = module.vnet.id
}
output "vnet_name" {
  description = "Virtual network name."
  value       = module.vnet.name
}
output "subnet_ids" {
  description = "Subnet IDs keyed by the exact Azure subnet name."
  value       = module.subnets.ids
}
output "network_security_group_ids" {
  description = "Created NSG IDs keyed by subnet name."
  value       = module.subnets.network_security_group_ids
}
output "route_table_ids" {
  description = "Created route table IDs keyed by subnet name."
  value       = module.subnets.route_table_ids
}
output "private_dns_zone_ids" {
  description = "Private DNS zone IDs keyed by zone name."
  value       = { for name, zone in azurerm_private_dns_zone.this : name => zone.id }
}
output "peering_ids" {
  description = "Local peering IDs; reciprocal links must be created separately."
  value       = { for name, peering in azurerm_virtual_network_peering.this : name => peering.id }
}
output "private_endpoint_ids" {
  description = "Private endpoint IDs keyed by endpoint name."
  value       = { for name, endpoint in azurerm_private_endpoint.this : name => endpoint.id }
}
