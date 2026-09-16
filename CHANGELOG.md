# Changelog

## 0.2.0

- Restore `AZ-TF-MOD-azvdc` composition, original input names, list-shaped subnet interface, naming defaults and output shapes.
- Restore VNet public/private DNS, CSV-backed NSGs/routes and complete child-resource outputs through released leaf module references.
- Forward previously ignored diagnostic-workspace and legacy DNS-selector inputs; sanitize defaults and document diagnostic state migration.
- Expose the original effective subnet suffix explicitly, with optional config root, subnet policies, tags and additional policy/DNS outputs.
- Document the original no-op availability-zone/flow-log/company inputs as deprecated compatibility fields.
- Keep topology ownership in callers; add synthetic examples and credential-free tests against both actual child modules.

## 0.1.0

Initial public scaffold. Its map-based subnet and wrapper-owned topology redesign is superseded by the reviewed compatibility-focused v0.2.0 design.
