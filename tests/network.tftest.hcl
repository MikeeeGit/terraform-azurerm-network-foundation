mock_provider "azurerm" {}

override_module {
  target = module.vnet
  outputs = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example"
    name = "vnet-example"
  }
}
override_module {
  target = module.subnets
  outputs = {
    ids = {
      application = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/virtualNetworks/vnet-example/subnets/application"
    }
    network_security_group_ids = {}
    route_table_ids            = {}
  }
}
variables {
  name                = "vnet-example"
  resource_group_name = "rg-example"
  location            = "uksouth"
  address_space       = ["10.40.0.0/16"]
  subnets = {
    application = { address_prefixes = ["10.40.1.0/24"] }
  }
}
run "minimal_has_no_optional_resources" {
  command = plan
  assert {
    condition     = length(azurerm_private_dns_zone.this) == 0 && length(azurerm_virtual_network_peering.this) == 0 && length(azurerm_private_endpoint.this) == 0
    error_message = "The minimal network must not create DNS, peerings or private endpoints implicitly."
  }
}
run "explicit_dns_and_peering" {
  command = plan
  variables {
    private_dns_zones = ["privatelink.blob.core.windows.net"]
    peerings = {
      to-hub = {
        remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
        triggers                  = { remote_address_space = "10.50.0.0/16" }
      }
    }
  }
  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.this["privatelink.blob.core.windows.net"].registration_enabled == false
    error_message = "Private DNS auto-registration must be disabled."
  }
  assert {
    condition     = azurerm_virtual_network_peering.this["to-hub"].allow_forwarded_traffic == false && azurerm_virtual_network_peering.this["to-hub"].use_remote_gateways == false
    error_message = "Peering must not enable forwarded traffic or gateway usage implicitly."
  }
}
run "peering_resync_contract" {
  command = plan
  variables {
    peerings = {
      to-hub = {
        remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
        triggers                  = { remote_address_space = "10.50.0.0/16,10.51.0.0/16" }
      }
    }
  }
  assert {
    condition     = azurerm_virtual_network_peering.this["to-hub"].triggers["remote_address_space"] == "10.50.0.0/16,10.51.0.0/16"
    error_message = "Remote address-space changes must reach the provider peering resync trigger."
  }
}
run "explicit_private_endpoint" {
  command = plan
  variables {
    private_dns_zones = ["privatelink.blob.core.windows.net"]
    private_endpoints = {
      pe-storage-example = {
        subnet_name            = "application"
        target_resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.Storage/storageAccounts/example"
        subresource_names      = ["blob"]
        private_dns_zone_names = ["privatelink.blob.core.windows.net"]
      }
    }
  }
  assert {
    condition     = azurerm_private_endpoint.this["pe-storage-example"].subnet_id == module.subnets.ids["application"]
    error_message = "Private endpoint must use the explicitly selected subnet."
  }
}
run "reject_unknown_dns_zone" {
  command = plan
  variables {
    private_endpoints = {
      pe-example = {
        subnet_name            = "application"
        target_resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.Storage/storageAccounts/example"
        subresource_names      = ["blob"]
        private_dns_zone_names = ["missing.example"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
}
run "reject_conflicting_gateway_flags" {
  command = plan
  variables {
    peerings = {
      to-hub = {
        remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
        allow_gateway_transit     = true
        use_remote_gateways       = true
      }
    }
  }
  expect_failures = [var.peerings]
}

run "reject_private_endpoint_in_delegated_subnet" {
  command = plan
  variables {
    subnets = {
      application = {
        address_prefixes = ["10.40.1.0/24"]
        delegation       = { name = "web", service_name = "Microsoft.Web/serverFarms" }
      }
    }
    private_endpoints = {
      pe-example = {
        subnet_name        = "application"
        target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.Storage/storageAccounts/example"
        subresource_names  = ["blob"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
}
run "reject_message_for_automatic_connection" {
  command = plan
  variables {
    private_endpoints = {
      pe-example = {
        subnet_name        = "application"
        target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.Storage/storageAccounts/example"
        subresource_names  = ["blob"]
        request_message    = "Only manual requests support a message."
      }
    }
  }
  expect_failures = [var.private_endpoints]
}
