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
| **generated-file-manifest.yaml** | Tracks expected generated package files plus missing or unexpected file-level outputs |
| **component-coverage.yaml** | Tracks package support for upstream components |
| **component-api-conformance.yaml** | Describes the currently verified generated-surface alignment with upstream components |
| **manual-api-inventory.yaml** | Lists exported APIs not derived from upstream components |

Together these manifests provide a structured view of the package's surface
area relative to the upstream Web Awesome ecosystem.

In addition to those report-stage manifests, the build also writes a small set
of generated integrity records under `manifests/integrity/`. These are
stage-owned checksum diagnostics used to detect when a later stage is working
from a modified or incomplete file tree.

---

## Manifest Generation

Manifests are generated during the **report** stage of the build pipeline.

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
    integrity/
        prune-output.yaml
        generate-output.yaml
    report/
        generated-file-manifest.yaml
        component-coverage.yaml
        component-api-conformance.yaml
        manual-api-inventory.yaml

reports/
    integrity/
        summary.md
    report/
        summary.md
        generated-files.md
        component-coverage.md
        component-api-conformance.md
        manual-api-inventory.md
```

### dev/manifests/

Human-maintained policy inputs used by the build process.

### manifests/

Generated structured artifacts describing the package state.

These files are produced automatically and should not be edited manually.

The `manifests/integrity/` subdirectory stores generated integrity records for
stage-owned file surfaces. Currently:

- `prune-output.yaml` records the prune-owned output surface
- `generate-output.yaml` records the generate-owned output surface

Later stages compare their current input surfaces against these records and
warn on drift. A dedicated final integrity-check tool reruns those comparisons
and fails if a required record is missing or if a surface no longer matches.

The `manifests/report/` subdirectory stores machine-readable artifacts written
by the report stage, including generated-file integrity, component coverage,
component API conformance, and manual API inventory manifests.

### reports/

Human-readable diagnostic reports generated from the manifests.

Reports summarize coverage and conformance results for developers and CI.
Current examples include:

- `reports/report/` for report-stage coverage and conformance summaries
- `reports/integrity/summary.md` for the final integrity-gate summary

---

## Reproducibility

The `manifests/` and `reports/` directories are fully regenerable.

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

The file is intentionally narrow. It should contain only human judgments such
as:

- the upstream component `tag`
- the desired coverage `status`
- optional explanatory `notes`

It should not duplicate discovered facts such as whether a wrapper, update
helper, or binding currently exists. Those facts are discovered during the
report stage and written to the generated manifest instead.

During reporting, the build system merges:

1. upstream metadata
2. discovered generated artifacts
3. policy annotations

to produce the final manifest written to:

```text
manifests/
```

This means `dev/manifests/component-coverage.policy.yaml` is the handwritten
input, while `manifests/report/component-coverage.yaml` is the generated merged
output used by the human-readable coverage report.

Policy files contain **only human decisions**, while generated manifests contain
the final merged result including discovered implementation facts.

## Integrity Records

Integrity records are generated build diagnostics written under:

```text
manifests/integrity/
```

They use a common schema and record:

- the owning `stage`
- the named file `surface`
- the surface root directories
- a deterministic file count and overall tree digest
- per-file relative paths, sizes, and content digests

The current integrity surfaces are:

- prune output:
  `inst/extdata/webawesome/` and `inst/www/wa/`
- generate output:
  generator-owned top-level `R/*.R` files and `inst/bindings/*.js`

These records are developer aids rather than security controls. Their role is
to detect local drift caused by hand edits, partial rebuilds, or incomplete
trees while preserving a reproducible final package build gate.

The final integrity gate also writes a short human-readable summary to:

```text
reports/integrity/summary.md
```

That report summarizes the current prune-output and generate-output
comparisons, including the recorded manifest path, the current surface roots,
and any mismatch details when the gate fails.
