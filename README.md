# terraform-azurerm-network-foundation

Reusable composition of a VNet/DNS module and a CSV-backed subnet/NSG/route module, adapted from `AZ-TF-MOD-azvdc`. It preserves the original wrapper interface, module addresses, naming defaults and outputs. The original deployment root also supports calling these leaf modules directly; this wrapper is an optional reuse layer.

This module creates no resource group or subscription. It combines [terraform-azurerm-vnet](https://github.com/MikeeeGit/terraform-azurerm-vnet) and [terraform-azurerm-subnets](https://github.com/MikeeeGit/terraform-azurerm-subnets), pinned to `v0.2.0`. Peerings, private endpoints, central DNS links, remote-state relationships and ACR belong to a caller such as [azure-network-foundation](https://github.com/MikeeeGit/azure-network-foundation).

## Usage

```hcl
module "network" {
  source = "git::https://github.com/MikeeeGit/terraform-azurerm-network-foundation.git?ref=v0.2.0"

  resource_group_name  = azurerm_resource_group.network.name
  location             = "uksouth"
  location_abbreviated = "uks"
  environment          = "dev"
  label                = "example-dev"
  vnet_ip_range        = "10.40.0.0/16"
  config_root          = "${path.root}/config"
  tags                 = { Environment = "dev" }

  subnets = [{
    name           = "application"
    address_prefix = "10.40.1.0/24"
    security_group = "enabled"
    endpoints      = ["Microsoft.Storage"]
  }]
}
```

Requires Terraform `>=1.9.0,<2.0.0` and AzureRM `>=4.33.0,<5.0.0`. Configure the provider and backend in your root. The required resource group must already exist or be supplied from a caller-managed resource.

## CSV and environment workflow

Keep environment data in tfvars and policy data in CSV. Module/resource blocks belong in `.tf` files; `.tfvars` files contain only input assignments. Each environment can use its own backend state while reusing the same module. No production backend, IDs or credentials are included.

By default the subnet child reads `${path.root}/config/<location_abbreviated>/<environment>/`. `config_root` selects another root, including an explicit absolute path. Filenames remain:

- `<environment>_<subnet name>_nsg.csv`
- `<environment>_<subnet name>_route_table.csv`

For the usage above these are `config/uks/dev/dev_application_nsg.csv` and `config/uks/dev/dev_application_route_table.csv`. `security_group` retains its original meaning: any nonempty string enables a new generated NSG; it is not an existing NSG ID or a rule-file selector.

NSG CSV:

```csv
name,priority,direction,access,protocol,source_port_range,destination_port_range,source_address_prefix,destination_address_prefix
allow-internal-https,200,Inbound,Allow,Tcp,*,443,VirtualNetwork,VirtualNetwork
```

Route CSV:

```csv
name,address_prefix,next_hop_type,next_hop_in_ip_address
blackhole-documentation-range,192.0.2.0/24,None,
```

Missing or empty files supply no custom rules. An enabled NSG still exists with Azure's default rules; removing its last custom row clears the managed custom rules. A route table is created only when its CSV contains rows. Invalid schemas and policy rows fail validation. Removing a route file/last row removes its route table and association. See the subnet module for full CSV validation and reserved Azure subnet-name behavior. No explicit outbound behavior is introduced unless the caller selects it.

## Inputs

| Input | Type | Default / meaning |
| --- | --- | --- |
| `resource_group_name`, `location`, `label` | string | Required |
| `location_abbreviated`, `environment` | string | Required CSV location/environment keys |
| `vnet_ip_range` | string | Required single CIDR; the VNet leaf accepts a list |
| `subnets` | list(object) | Required, may be `[]`; original schema below |
| `vnet_suffix` | string | `vnet-01`, preserving the original wrapper VNet name |
| `subnet_vnet_suffix` | string | `vnet01`, preserving the original effective subnet child default |
| `config_root` | string or null | `null` for `${path.root}/config` |
| `tags` | map(string) | `{}`; applied to both children |
| `dns_servers` | list(string) | `[]` for Azure DNS |
| `ddos_plan_id` | string | `""`; optional existing plan association |
| `diag_log_workspace` | string or null | `null`; explicit existing workspace enables VNet diagnostics |
| `dns`, `private_dns` | list(object) | `[]`; public/private zones with A/CNAME/MX records |
| `dns_zone_name` | string | `""`; optional legacy selector for one configured private zone link |

Original subnet fields remain required: `name`, `address_prefix`, `security_group` (strings) and `endpoints` (list of strings). Optional additions are `default_outbound_access_enabled` (bool), `private_endpoint_network_policies` (string), `private_link_service_network_policies_enabled` (bool), `service_endpoint_policy_ids` (list(string), default `[]`), `bgp_route_propagation_enabled` (bool, default `true`) and `delegation` (`{name, service_name, actions = optional(list(string), [])}`). Null/unset policy fields retain provider behavior. See [basic](examples/basic) for an explicit outbound choice.

The two suffix defaults intentionally differ: originally the wrapper chose `vnet-01` for its VNet but omitted the child subnet suffix, whose default was `vnet01`. The new explicit `subnet_vnet_suffix` documents that behavior. Changing either suffix may rename resources; do not silently harmonize them during migration.

DNS uses the VNet child's original schema: a zone has `zone_name`, optional `a_records = [{name, ip}]`, `cname_records = [{name, target}]`, and `mx_records = [{preference, exchange}]`. TTL remains 300; MX is apex-only. Each private zone gets one non-registering VNet link. Both `dns_zone_name` and `diag_log_workspace` now reach the child; the original wrapper declared but failed to forward them. Diagnostics preserve `VMProtectionAlerts` and `AllMetrics`. The workspace null/non-null status must be known at plan time.

Deprecated compatibility inputs remain accepted but unused, matching the original wrapper: `availability_zones` (default `["1"]`), `nsg_flow_log_storage_account_id` (default `null`), and `company_abbreviation` (default `""`). They do not create zonal subnets, flow logs or an extra naming prefix. VNets/subnets are regional. Add naming components to `label`; implement any flow-log design explicitly in the caller.

## Outputs

Original outputs are retained: `vnet` (complete VNet resource), `subnets` (complete resource map), `subnet_ids`, `subnet_address_prefixes` (map of **strings**, using each subnet's first prefix), `subnets_file_paths`, `rootpath` and `subnets_subnet_nsg_rules`.

Additional outputs expose `route_table_file_paths`, `subnet_route_table_rules`, `virtual_network_id`, `virtual_network_name`, `public_dns_zone_ids`, `private_dns_zone_ids`, `diagnostic_setting_id`, `network_security_group_ids` and `route_table_ids`. Subnet/policy map keys are logical input subnet names; DNS map keys are zone names.

## Examples and verification

- [Basic](examples/basic): CSV-backed subnet security and routing.
- [Hub and two spokes](examples/hub-spoke): three compositions, reciprocal peerings, shared private DNS, CSV policies and optional NAT egress.
- [Migration notes](docs/MIGRATION.md): retained behavior and intentional compatibility changes.

```sh
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

The tests use mocked AzureRM resources across both real child modules, including a mocked apply to check diagnostic forwarding. No cloud authentication or real apply is used. They verify naming, output shapes, CSV propagation, DNS/diagnostics, optional subnet settings, empty topology and rejected inputs. They do not prove live networking, permissions or deployment success. Shared GitHub Actions and Azure Pipelines validate the module and examples without cloud credentials.

Licensed under [Apache-2.0](LICENSE). See [contributing](CONTRIBUTING.md) and [security reporting](SECURITY.md).

## CI change scope

Markdown-only edits use lightweight required GitHub checks and are excluded from automatic Azure validation builds. Changes to Terraform, application code, scripts, workflow definitions or executable examples still run full validation, including examples stored under docs/. Mixed changes also run full validation. Manual GitHub runs and unknown Git comparison ranges default to full validation.
