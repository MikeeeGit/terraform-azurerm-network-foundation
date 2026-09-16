output "vnet" {
  description = "Complete VNet resource, preserving the original wrapper output."
  value       = module.vnet.vnet
}

output "subnets" {
  description = "Complete subnet resource map keyed by the original subnet name."
  value       = module.subnets.subnets
}

output "subnet_ids" {
  description = "Subnet IDs keyed by input subnet name."
  value       = module.subnets.subnet_ids
}

output "subnet_address_prefixes" {
  description = "Primary address prefix per subnet, preserving the original string-valued map."
  value       = { for name, subnet in module.subnets.subnets : name => subnet.address_prefixes[0] }
}

output "subnets_file_paths" {
  description = "NSG CSV paths from the subnet child."
  value       = module.subnets.file_paths
}

output "rootpath" {
  description = "Root module path from the subnet child."
  value       = module.subnets.rootpath
}

output "subnets_subnet_nsg_rules" {
  description = "Parsed NSG CSV data from the subnet child."
  value       = module.subnets.subnet_nsg_rules
}

output "route_table_file_paths" {
  description = "Route-table CSV paths from the subnet child."
  value       = module.subnets.route_table_file_paths
}

output "subnet_route_table_rules" {
  description = "Parsed route-table CSV data from the subnet child."
  value       = module.subnets.subnet_route_table_rules
}

output "virtual_network_id" {
  description = "VNet ID for caller-owned peerings and private endpoints."
  value       = module.vnet.id
}

output "virtual_network_name" {
  description = "Composed VNet name."
  value       = module.vnet.name
}

output "public_dns_zone_ids" {
  description = "Created public DNS zone IDs keyed by zone name."
  value       = module.vnet.public_dns_zone_ids
}

output "private_dns_zone_ids" {
  description = "Created private DNS zone IDs keyed by zone name."
  value       = module.vnet.private_dns_zone_ids
}

output "diagnostic_setting_id" {
  description = "Diagnostic setting ID or null when disabled."
  value       = module.vnet.diagnostic_setting_id
}

output "network_security_group_ids" {
  description = "Created NSG IDs keyed by subnet name."
  value       = module.subnets.network_security_group_ids
}

output "route_table_ids" {
  description = "Created route-table IDs keyed by subnet name."
  value       = module.subnets.route_table_ids
}
