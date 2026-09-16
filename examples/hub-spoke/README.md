# Two foundations with caller-owned peering

Creates two VNets and reciprocal peerings. Peering belongs to the caller, as in the original architecture; the wrapper composes only VNet/DNS and subnet policy. This minimal topology intentionally has no gateway, firewall, private endpoint, central DNS or Internet egress. Subnets omit custom NSGs and route tables.
