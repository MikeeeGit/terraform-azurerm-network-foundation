resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = module.subnets.ids[each.value.subnet_name]
  tags                = var.tags

  private_service_connection {
    name                           = each.key
    is_manual_connection           = each.value.is_manual_connection
    request_message                = each.value.request_message
    private_connection_resource_id = each.value.target_resource_id
    subresource_names              = each.value.subresource_names
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_names) == 0 ? [] : [each.value.private_dns_zone_names]
    content {
      name                 = "default"
      private_dns_zone_ids = [for zone in sort(tolist(private_dns_zone_group.value)) : azurerm_private_dns_zone.this[zone].id]
    }
  }
}
