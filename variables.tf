variable "resource_group_name" {
  description = "Existing resource group for the VNet, DNS zones and diagnostics."
  type        = string
  nullable    = false
  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "label" {
  description = "Naming prefix. The VNet name is <label>-<vnet_suffix>."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]{0,62}[A-Za-z0-9_]$", "${var.label}-${var.vnet_suffix}"))
    error_message = "The composed VNet name must be 2-64 Azure-compatible characters, start with an alphanumeric and end with an alphanumeric or underscore."
  }
}

variable "location" {
  description = "Azure region for the virtual network."
  type        = string
  nullable    = false
  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "vnet_ip_range" {
  description = "Single VNet CIDR, preserving the original wrapper interface; the leaf module accepts a list."
  type        = string
  nullable    = false
  validation {
    condition     = can(cidrhost(var.vnet_ip_range, 0))
    error_message = "vnet_ip_range must be a valid CIDR."
  }
}

variable "tags" {
  description = "Resource tags; the original module's generated Name tag is retained on the VNet and DNS zones."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "dns_servers" {
  description = "Custom DNS server IPs. Empty uses Azure-provided DNS; do not also manage these with virtual_network_dns_servers."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for ip in var.dns_servers : can(cidrhost("${ip}/32", 0)) || can(cidrhost("${ip}/128", 0))])
    error_message = "dns_servers must contain IP addresses without CIDR suffixes."
  }
}

variable "vnet_suffix" {
  description = "Suffix appended to label. Preserves the original wrapper default vnet-01."
  type        = string
  default     = "vnet-01"
  nullable    = false
}

variable "ddos_plan_id" {
  description = "Existing Azure DDoS Protection Plan resource ID; an empty string omits the association."
  type        = string
  default     = ""
  nullable    = false
  validation {
    condition     = var.ddos_plan_id == "" || can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/ddosProtectionPlans/[^/]+$", var.ddos_plan_id))
    error_message = "ddos_plan_id must be empty or a DDoS Protection Plan resource ID."
  }
}

variable "diag_log_workspace" {
  description = "Existing Log Analytics workspace ID for VMProtectionAlerts and AllMetrics. Null disables diagnostics; null/non-null must be known during planning."
  type        = string
  default     = null
  validation {
    condition     = var.diag_log_workspace == null ? true : can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.diag_log_workspace))
    error_message = "diag_log_workspace must be null or a Log Analytics workspace resource ID. Empty strings are not workspace IDs."
  }
}

variable "dns_zone_name" {
  description = "Optional legacy selector for a zone in private_dns. That zone receives the named <label>-dns-zone-private link instead of a second duplicate link."
  type        = string
  default     = ""
  nullable    = false
  validation {
    condition     = var.dns_zone_name == "" || contains([for zone in var.private_dns : zone.zone_name], var.dns_zone_name)
    error_message = "dns_zone_name must be empty or exactly match a zone_name in private_dns."
  }
}

variable "dns" {
  description = "Public DNS zones and records. A and CNAME records are keyed by zone and record name; MX records are at the zone apex. TTL is 300 seconds."
  type = list(object({
    zone_name = string
    a_records = optional(list(object({
      name = string
      ip   = string
    })), [])
    cname_records = optional(list(object({
      name   = string
      target = string
    })), [])
    mx_records = optional(list(object({
      preference = number
      exchange   = string
    })), [])
  }))
  default  = []
  nullable = false

  validation {
    condition = length(distinct([for zone in var.dns : lower(zone.zone_name)])) == length(var.dns) && alltrue([
      for zone in var.dns : try(
        length(zone.zone_name) <= 253 && length(split(".", zone.zone_name)) >= 2 &&
        alltrue([for label in split(".", zone.zone_name) : can(regex("^[A-Za-z0-9_]([A-Za-z0-9_-]{0,61}[A-Za-z0-9_])?$", label))]),
      false)
    ])
    error_message = "dns zones must have unique domain names with at least two valid labels."
  }
  validation {
    condition = alltrue(flatten([
      for zone in var.dns : concat(
        [for record in zone.a_records : try(length(trimspace(record.name)) > 0 && can(cidrnetmask("${record.ip}/32")), false)],
        [for record in zone.cname_records : try(length(trimspace(record.name)) > 0 && length(trimspace(record.target)) > 0, false)],
        [for record in zone.mx_records : try(record.preference >= 0 && record.preference <= 65535 && floor(record.preference) == record.preference && length(trimspace(record.exchange)) > 0, false)]
      )
    ]))
    error_message = "dns records need nonempty names/targets, IPv4 A addresses, and integer MX preferences from 0 to 65535."
  }
  validation {
    condition = alltrue([
      for zone in var.dns :
      length(distinct([for record in zone.a_records : lower(record.name)])) == length(zone.a_records) &&
      length(distinct([for record in zone.cname_records : lower(record.name)])) == length(zone.cname_records) &&
      length(setintersection(toset([for record in zone.a_records : lower(record.name)]), toset([for record in zone.cname_records : lower(record.name)]))) == 0
    ])
    error_message = "dns must not repeat an A/CNAME name or assign both an A and CNAME record to the same name."
  }
}

variable "private_dns" {
  description = "Private DNS zones and records. A and CNAME records are keyed by zone and record name; MX records are at the zone apex. TTL is 300 seconds."
  type = list(object({
    zone_name = string
    a_records = optional(list(object({
      name = string
      ip   = string
    })), [])
    cname_records = optional(list(object({
      name   = string
      target = string
    })), [])
    mx_records = optional(list(object({
      preference = number
      exchange   = string
    })), [])
  }))
  default  = []
  nullable = false

  validation {
    condition = length(distinct([for zone in var.private_dns : lower(zone.zone_name)])) == length(var.private_dns) && alltrue([
      for zone in var.private_dns : try(
        length(zone.zone_name) <= 253 && length(split(".", zone.zone_name)) >= 2 &&
        alltrue([for label in split(".", zone.zone_name) : can(regex("^[A-Za-z0-9_]([A-Za-z0-9_-]{0,61}[A-Za-z0-9_])?$", label))]),
      false)
    ])
    error_message = "private_dns zones must have unique domain names with at least two valid labels."
  }
  validation {
    condition = alltrue(flatten([
      for zone in var.private_dns : concat(
        [for record in zone.a_records : try(length(trimspace(record.name)) > 0 && can(cidrnetmask("${record.ip}/32")), false)],
        [for record in zone.cname_records : try(length(trimspace(record.name)) > 0 && length(trimspace(record.target)) > 0, false)],
        [for record in zone.mx_records : try(record.preference >= 0 && record.preference <= 65535 && floor(record.preference) == record.preference && length(trimspace(record.exchange)) > 0, false)]
      )
    ]))
    error_message = "private_dns records need nonempty names/targets, IPv4 A addresses, and integer MX preferences from 0 to 65535."
  }
  validation {
    condition = alltrue([
      for zone in var.private_dns :
      length(distinct([for record in zone.a_records : lower(record.name)])) == length(zone.a_records) &&
      length(distinct([for record in zone.cname_records : lower(record.name)])) == length(zone.cname_records) &&
      length(setintersection(toset([for record in zone.a_records : lower(record.name)]), toset([for record in zone.cname_records : lower(record.name)]))) == 0
    ])
    error_message = "private_dns must not repeat an A/CNAME name or assign both an A and CNAME record to the same name."
  }
}

variable "location_abbreviated" {
  description = "Region key used to select CSV files below config_root/<location_abbreviated>/<environment>."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Environment directory and CSV filename prefix, for example dev."
  type        = string
  nullable    = false
}

variable "subnets" {
  description = "Original list interface. security_group selects CSV-backed NSG creation; endpoints are Azure service endpoint names. New optional attributes pass through to the subnet module."
  type = list(object({
    name                                          = string
    address_prefix                                = string
    security_group                                = string
    endpoints                                     = list(string)
    default_outbound_access_enabled               = optional(bool)
    private_endpoint_network_policies             = optional(string)
    private_link_service_network_policies_enabled = optional(bool)
    service_endpoint_policy_ids                   = optional(list(string), [])
    bgp_route_propagation_enabled                 = optional(bool, true)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }))
  }))
  nullable = false
}

variable "subnet_vnet_suffix" {
  description = "Suffix passed to subnet/NSG/route-table naming. vnet01 preserves the original wrapper's effective child default, distinct from its VNet suffix. Set explicitly only after reviewing the rename plan."
  type        = string
  default     = "vnet01"
  nullable    = false
}

variable "config_root" {
  description = "CSV configuration root. Null preserves <root module>/config; a supplied path is resolved by the subnet child."
  type        = string
  default     = null
}

variable "availability_zones" {
  description = "Deprecated compatibility input; it never affected resources in the original wrapper. VNets/subnets are regional, not zonal."
  type        = list(string)
  default     = ["1"]
}

variable "nsg_flow_log_storage_account_id" {
  description = "Deprecated compatibility input; accepted but unused, as in the original wrapper. This module does not create flow logs."
  type        = string
  default     = null
}

variable "company_abbreviation" {
  description = "Deprecated compatibility input; accepted but unused, as in the original wrapper. Include naming components in label instead."
  type        = string
  default     = ""
}
