module "vnet" {
  source = "git::https://github.com/MikeeeGit/terraform-azurerm-vnet.git?ref=v0.2.0"

  resource_group_name = var.resource_group_name
  label               = var.label
  location            = var.location
  vnet_ip_range       = [var.vnet_ip_range]
  vnet_suffix         = var.vnet_suffix
  tags                = var.tags
  dns_servers         = var.dns_servers
  ddos_plan_id        = var.ddos_plan_id
  dns                 = var.dns
  private_dns         = var.private_dns
  dns_zone_name       = var.dns_zone_name
  diag_log_workspace  = var.diag_log_workspace
}

module "subnets" {
  source = "git::https://github.com/MikeeeGit/terraform-azurerm-subnets.git?ref=v0.2.0"

  resource_group_name  = var.resource_group_name
  location             = var.location
  vnet_name            = module.vnet.vnet.name
  subnets              = var.subnets
  label                = var.label
  location_abbreviated = var.location_abbreviated
  environment          = var.environment
  vnet_suffix          = var.subnet_vnet_suffix
  config_root          = var.config_root
  tags                 = var.tags
}
