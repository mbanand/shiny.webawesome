# Manifests

The shiny.webawesome build system produces a set of structured manifests that
describe the relationship between upstream Web Awesome components and the
generated R package.

These manifests are machine-readable artifacts used for coverage analysis,
API conformance checks, and diagnostic reporting.

They are generated automatically as part of the build pipeline.

---

## Manifest Categories

The project maintains four primary manifests:

| Manifest | Purpose |
|--------|--------|
| **generated-file-manifest.yaml** | Lists all files produced by generation scripts |
| **component-coverage.yaml** | Tracks package support for upstream components |
| **component-api-conformance.yaml** | Describes API-level alignment with upstream components |
| **manual-api-inventory.yaml** | Lists exported APIs not derived from upstream components |

Together these manifests provide a structured view of the package's surface
area relative to the upstream Web Awesome ecosystem.

---

## Manifest Generation

Manifests are generated during the **generate** stage of the build pipeline.

They are derived from:

- upstream metadata (`custom-elements.json`)
- discovered generated outputs
- a small human-maintained policy file

Manifests are deterministic build artifacts and should not be manually edited.

---

## Directory Layout

The repository separates **policy inputs**, **generated manifests**, and
**human-readable reports**.

```text
dev/manifests/
    component-coverage.policy.yaml

manifests/
    generated-file-manifest.yaml
    component-coverage.yaml
    component-api-conformance.yaml
    manual-api-inventory.yaml

report/
    summary.md
    component-coverage.md
    component-api-conformance.md
```

### dev/manifests/

Human-maintained policy inputs used by the build process.

### manifests/

Generated structured artifacts describing the package state.

These files are produced automatically and should not be edited manually.

### report/

Human-readable diagnostic reports generated from the manifests.

Reports summarize coverage and conformance results for developers and CI.

---

## Reproducibility

The `manifests/` and `report/` directories are fully regenerable.

Running the build pipeline will recreate all manifest and report artifacts from
upstream metadata and repository policy inputs.

---

## Policy Inputs

Some manifests incorporate a small handwritten policy layer used to record
intentional project decisions.

For example, the component coverage manifest merges upstream component metadata
with the file:

```text
dev/manifests/component-coverage.policy.yaml
```

This policy file allows developers to:

- mark components as `planned` or `excluded`
- record explanatory notes
- explicitly override inferred coverage status

During generation, the build system merges:

1. upstream metadata
2. discovered generated artifacts
3. policy annotations

to produce the final manifest written to:

```text
manifests/
```

Policy files contain **only human decisions**, while generated manifests contain
the final merged result including discovered implementation facts.
