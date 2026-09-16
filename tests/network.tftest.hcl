mock_provider "azurerm" {
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-network-rg/providers/Microsoft.Network/virtualNetworks/example-dev-vnet-01"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-network-rg/providers/Microsoft.Network/virtualNetworks/example-dev-vnet-01/subnets/application"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-network-rg/providers/Microsoft.Network/networkSecurityGroups/application-nsg"
    }
  }
  mock_resource "azurerm_route_table" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-network-rg/providers/Microsoft.Network/routeTables/application-rt"
    }
  }
}
variables {
  resource_group_name  = "example-network-rg"
  location             = "uksouth"
  location_abbreviated = "uks"
  environment          = "dev"
  label                = "example-dev"
  vnet_ip_range        = "10.40.0.0/16"
  subnets = [{
    name           = "application"
    address_prefix = "10.40.1.0/24"
    security_group = "enabled"
    endpoints      = ["Microsoft.Storage"]
  }]
  config_root = "tests/fixtures/config"
}
run "original_composition_and_csv" {
  command = plan
  assert {
    condition     = output.vnet.name == "example-dev-vnet-01" && output.subnets["application"].name == "example-dev-vnet01-application" && output.subnets["application"].virtual_network_name == output.vnet.name
    error_message = "The wrapper must preserve original VNet/subnet suffixes and pass the created VNet to its subnet child."
  }
  assert {
    condition     = output.subnet_address_prefixes["application"] == "10.40.1.0/24" && output.subnets["application"].service_endpoints == toset(["Microsoft.Storage"])
    error_message = "The wrapper's original string-valued prefix map and endpoint input must be preserved."
  }
  assert {
    condition     = output.subnets_file_paths["application"] == "tests/fixtures/config/uks/dev/dev_application_nsg.csv" && output.subnets_subnet_nsg_rules["application"][0].name == "allow-internal-https" && output.subnet_route_table_rules["application"][0].next_hop_type == "None" && contains(keys(output.network_security_group_ids), "application") && contains(keys(output.route_table_ids), "application")
    error_message = "CSV paths, decoded rows and created policy outputs must flow through the wrapper."
  }
  assert {
    condition     = output.diagnostic_setting_id == null && length(output.private_dns_zone_ids) == 0 && length(output.public_dns_zone_ids) == 0
    error_message = "Safe defaults must leave diagnostics and DNS disabled."
  }
}
run "dns_diagnostics_and_optional_subnet_settings" {
  command = apply
  variables {
    dns_servers        = ["10.40.0.4"]
    tags               = { Environment = "dev" }
    diag_log_workspace = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-monitor-rg/providers/Microsoft.OperationalInsights/workspaces/example-workspace"
    dns                = [{ zone_name = "example.org", a_records = [{ name = "www", ip = "192.0.2.10" }] }]
    private_dns        = [{ zone_name = "internal.example.test", cname_records = [{ name = "api", target = "app.internal.example.test" }] }]
    dns_zone_name      = "internal.example.test"
    subnet_vnet_suffix = ""
    subnets = [{
      name                                          = "application"
      address_prefix                                = "10.40.1.0/24"
      security_group                                = "enabled"
      endpoints                                     = []
      default_outbound_access_enabled               = false
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = false
      bgp_route_propagation_enabled                 = false
      delegation = {
        name         = "web"
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }]
  }
  assert {
    condition     = output.vnet.dns_servers == tolist(["10.40.0.4"]) && output.vnet.tags.Environment == "dev" && contains(keys(output.public_dns_zone_ids), "example.org") && contains(keys(output.private_dns_zone_ids), "internal.example.test")
    error_message = "DNS settings and tags must pass through the original VNet child."
  }
  assert {
    condition     = output.subnets["application"].name == "example-dev-application" && !output.subnets["application"].default_outbound_access_enabled && output.subnets["application"].private_endpoint_network_policies == "Enabled" && !output.subnets["application"].private_link_service_network_policies_enabled && one(one(output.subnets["application"].delegation).service_delegation).name == "Microsoft.Web/serverFarms"
    error_message = "Explicit suffix and new optional subnet policies must reach the child without changing defaults."
  }
  assert {
    condition     = output.diagnostic_setting_id != null
    error_message = "An explicitly supplied workspace must enable diagnostics through the wrapper."
  }
}
run "empty_topology" {
  command = plan
  variables { subnets = [] }
  assert {
    condition     = length(output.subnets) == 0 && length(output.subnet_ids) == 0 && length(output.subnets_file_paths) == 0
    error_message = "An empty subnet list must remain valid."
  }
}
run "reject_invalid_cidr" {
  command = plan
  variables { vnet_ip_range = "bad-cidr" }
  expect_failures = [var.vnet_ip_range]
}
run "reject_missing_selected_zone" {
  command = plan
  variables { dns_zone_name = "missing.example.test" }
  expect_failures = [var.dns_zone_name]
}
