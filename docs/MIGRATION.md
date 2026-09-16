# Migration to v0.2.0

## From AZ-TF-MOD-azvdc

Keep the existing module block name, values and CSV layout while changing the source. The wrapper still composes `module.vnet` and `module.subnets`; `vnet_ip_range` remains a single string and `subnets` remains the original four-field list. Original outputs retain their shapes, including the string-valued `subnet_address_prefixes` map. Child resource labels and policy keys follow the originals.

Review the following deliberate changes:

1. `diag_log_workspace` is now forwarded. It defaults to null because a public module must not contain an estate workspace ID. The original wrapper declared this input but ignored it; the old VNet leaf used its own default instead. To retain existing diagnostics, explicitly provide the workspace actually used in state. The VNet child includes a move from its singleton diagnostic address to `[0]`; null now plans removal of an existing setting.
2. `dns_zone_name` is now forwarded, and the child fixes the original incorrect zone-key lookup and duplicate link. Keep it empty to preserve normal `<zone>-link` addresses. An explicit selector must match a zone in `private_dns`; selecting it changes to the legacy named link and requires plan review.
3. `subnet_vnet_suffix = "vnet01"` makes the original effective child default explicit. The VNet default stays `vnet-01`. There is no forced naming cleanup. A root that historically called the leaf with `vnet_suffix = ""` must make the same explicit choice when adopting this wrapper.
4. Tags now reach subnet-owned NSGs and route tables as well as the VNet/DNS resources. Optional subnet policies and `config_root` are additive; omitted policy options preserve provider behavior. The original generated VNet/DNS Name tag precedence remains.
5. Empty inline NSG rules are explicitly managed so removing the final CSV rule clears it. Azure-reserved subnet names work for every VNet, without estate-specific allowlists. CSV shape/content and inputs receive validation. Route tables retain the original create-only-when-rows-exist behavior.
6. Terraform >=1.9 and AzureRM >=4.33,<5 are required. Upgrade providers with your normal plan/review process; this repository contains no backend or live state.

`availability_zones`, `nsg_flow_log_storage_account_id` and `company_abbreviation` remain accepted no-op compatibility inputs. They were unused in the original wrapper and must not be treated as implemented capabilities.

Run a plan against the actual existing state before applying. Changes to module block names, labels, environment keys, CSV filenames or suffixes can change resource addresses or names. Keep private environment tfvars, backend values, plans and state out of public repositories. No live migration or Azure deployment is implied by the mock tests.

## From the provisional v0.1.0 public wrapper

v0.2.0 is a breaking restoration of the reviewed original interface. The provisional map-based subnet interface, wrapper-owned peerings/private endpoints and separate wrapper DNS ownership are superseded by the original leaf composition. Move caller-owned topology to your root before upgrading. Rename inputs to the original schema and review all resource addresses, imports and moved blocks against your own state. No blanket move is safe across these different ownership boundaries.

The original `AZ-TF-azvdc` root bypassed this wrapper and called both leaves directly. Keeping that direct composition is supported; adopting this wrapper is optional and changes module paths, so it is a separate state migration decision.
