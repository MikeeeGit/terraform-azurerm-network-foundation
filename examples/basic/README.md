# CSV-backed foundation

Creates a VNet, application subnet, NSG with a CSV rule and route table with an explicit AzureMonitor service-tag route. Uses the original wrapper naming defaults. The explicit outbound=false demonstrates an opt-in policy; this example provides no Internet egress service. The Internet next-hop route does not supply NAT; add explicit egress before expecting monitoring traffic to public endpoints. The [hub/spoke example](../hub-spoke) includes optional NAT gateways. Edit `config/uks/dev/` for policy.

Authenticate and set `ARM_SUBSCRIPTION_ID` before an intentional plan/apply. Static validation uses no Azure credentials.
