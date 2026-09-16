# CSV-backed foundation

Creates a VNet, application subnet, NSG with a CSV rule and route table with a documentation-range discard route. Uses the original wrapper naming defaults. The explicit outbound=false demonstrates an opt-in policy; this example provides no Internet egress service. Edit `config/uks/dev/` for policy.

Authenticate and set `ARM_SUBSCRIPTION_ID` before an intentional plan/apply. Static validation uses no Azure credentials.
