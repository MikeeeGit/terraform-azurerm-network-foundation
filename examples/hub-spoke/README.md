# Hub and spoke example

Creates two resource groups, VNets and protected workload subnets in one subscription, then explicitly creates both directions of VNet peering. The example uses synthetic, non-overlapping address spaces.

Peering is deliberately composed after both networks. Passing each module's output into the other module's peerings input creates a dependency cycle. The address-space trigger requests resynchronization when the remote range changes.

This topology contains no firewall, gateway, NAT Gateway, DNS resolver or workloads, and does not claim transit routing or central egress. Adapt those separately to your architecture. A real deployment needs authentication and may incur charges; CI only initializes without a backend and validates syntax/schema.

Run from this directory: terraform init -backend=false -lockfile=readonly, then terraform validate. For a real deployment, use an appropriately protected backend and private reviewed plan workflow.
