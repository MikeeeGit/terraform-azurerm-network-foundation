module "vnet" {
  source = "git::https://github.com/MikeeeGit/terraform-azurerm-vnet.git?ref=bf6eed39dfa7bbdd5fcc9307da6cd558d0d2f31d"

  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  address_space              = var.address_space
  dns_servers                = var.dns_servers
  tags                       = var.tags
  ddos_protection_plan_id    = var.ddos_protection_plan_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
}

module "subnets" {
  source = "git::https://github.com/MikeeeGit/terraform-azurerm-subnets.git?ref=76cefbd6b24bcbb63f3fc0c56ce4c3422b2ece2f"

  resource_group_name  = var.resource_group_name
  location             = var.location
  virtual_network_name = module.vnet.name
  subnets              = var.subnets
  tags                 = var.tags
}
