# Component Coverage

The **component coverage manifest** tracks which upstream Web Awesome
components are supported by the shiny.webawesome package.

The manifest provides a structured inventory of upstream components and the
package's implementation status for each.

This information is used by the reporting stage to detect coverage gaps and
track progress toward full upstream support.

## Purpose

The coverage manifest serves several important roles:

- detecting newly introduced upstream components
- identifying missing wrapper implementations
- documenting intentional exclusions
- providing a transparent inventory of package support

The manifest provides a foundation for more detailed **API conformance
analysis**, which evaluates property, attribute, event, and slot coverage for
each implemented component.

---

## Coverage Manifest Location

Coverage data is stored in:

```text
build/manifests/component-coverage.yaml
```

Each entry corresponds to a single upstream component defined in
`custom-elements.json`.

The manifest records:

- the upstream component tag
- the generated R wrapper (if present)
- the generated update function (if present)
- the component's support status
- optional explanatory notes

---

## Policy Layer

A small human-maintained policy file allows developers to annotate the
coverage manifest with intentional decisions.

This file is located at:

```text
dev/manifests/component-coverage.policy.yaml
```

Policy annotations may specify:

- components intentionally excluded
- components planned for future implementation
- explanatory notes

During the build process the generator merges:

- upstream component metadata
- discovered generated outputs
- policy annotations

to produce the final coverage manifest.

---

## Coverage Manifest Schema

The generated coverage manifest uses the following structure:

```yaml
schema_version: 1
manifest_type: component_coverage
generated_at: "2026-03-12T19:30:00Z"

upstream:
  source_file: vendor/webawesome/custom-elements.json
  source_version: "x.y.z"

summary:
  total_components: 42
  covered: 18
  partial: 4
  planned: 8
  excluded: 5
  unsupported: 7

components:
  - tag: wa-button
    component_name: button
    status: covered
    notes: null

    r_function:
      name: wa_button
      exists: true

    update_function:
      name: update_wa_button
      exists: true

    binding:
      name: wa-button
      exists: true
```

Each component entry represents a single upstream custom element.

### Key Fields

| Field | Description |
|------|-------------|
| `tag` | Upstream custom element tag |
| `component_name` | Normalized component identifier (snake_case) |
| `status` | Package support status |
| `notes` | Optional explanatory note |
| `r_function` | Generated wrapper function information |
| `update_function` | Generated Shiny update function information |
| `binding` | Generated input/output binding information |

The `exists` fields indicate whether the corresponding generated artifact was
discovered during the build process.

---

## Policy File Schema

Human policy decisions are stored in:

```text
dev/manifests/component-coverage.policy.yaml
```

Example:

```yaml
schema_version: 1

components:
  - tag: wa-carousel
    status: planned
    notes: Deferred until base update patterns are stable.

  - tag: wa-split-panel
    status: excluded
    notes: Not currently targeted for shiny.webawesome.
```

Allowed fields per entry:

| Field | Required | Description |
|------|------|-------------|
| `tag` | yes | Upstream component tag |
| `status` | yes | Coverage status |
| `notes` | no | Optional explanatory note |

Only **policy decisions** belong in this file.  
Generated facts must not be recorded here.

---

## Merge Rules

The coverage manifest is produced by merging three sources:

1. upstream component metadata (`custom-elements.json`)
2. discovered generated artifacts
3. the handwritten policy file

The merge process operates as follows:

1. All upstream components are enumerated.
2. Expected wrapper, update, and binding names are derived.
3. The build process discovers whether those artifacts exist.
4. Policy annotations are applied when present.

If a policy entry exists for a component, the policy **status and notes
override the inferred status**.

If no policy entry exists, a default status is assigned:

- wrapper exists → `covered`
- wrapper missing → `unsupported`

---

## Policy and Discovery Conflicts

Policy decisions may intentionally differ from discovered implementation facts.

For example, a component may have generated artifacts but still be marked
`unsupported` while implementation work is incomplete.

In such cases:

- the **policy status is retained**
- discovered `exists` fields continue to reflect the actual generated state

Example:

```yaml
status: unsupported
r_function:
  exists: true
```

These mismatches are surfaced during the **report stage** of the build pipeline
as warnings or errors.

This separation ensures that:

- policy decisions remain explicit
- implementation facts remain observable
- reporting tools can highlight inconsistencies.

## Coverage Status Values

Components may have one of several support statuses.

Typical values include:

- `covered`
- `partial`
- `planned`
- `excluded`
- `unsupported`

These statuses allow the report stage to clearly describe the current level of
package support for upstream components.


