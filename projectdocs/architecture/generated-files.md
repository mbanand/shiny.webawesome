# Generated File Guardrails

This document defines guardrails for working with generated files in the
`shiny.webawesome` repository.

The project is generator-driven. Many files are produced automatically from
Web Awesome metadata and should not be edited directly.

---

# Purpose

These guardrails exist to prevent accidental edits to generated artifacts.

If generated output is incorrect, the fix should be made in the generator
logic, templates, metadata parsing, or build pipeline, and the outputs should
then be regenerated.

---

# Generated Package Source Areas

The following package source areas contain generated files:

- generated component files under `R/` such as `R/wa_select.R`
- `inst/bindings/`
- `inst/extdata/webawesome/`
- `manifests/`
- `reports/`

These files should not be edited directly.

Depending on the build workflow, generated or derived runtime assets may also
exist under:

- `inst/www/wa/`

Runtime assets should not be manually edited unless the intended change is to
the pruning or bundling logic.

## Tracked generated surfaces

Not all generated files in this repository are disposable local artifacts.

Several generated or prune-owned source-tree surfaces are intentionally
**tracked in git** because source-tree package builds, remote checks, or later
pipeline stages rely on them being present without requiring a fresh local
rebuild first.

Important tracked generated surfaces include:

- generated package files under top-level `R/`
- generated bindings under `inst/bindings/`
- prune-owned runtime assets under `inst/www/wa/`
- the shipped prune-owned version file `inst/SHINY.WEBAWESOME_VERSION`
- prune-owned generation metadata under `inst/extdata/webawesome/`

The fact that these files are generated does **not** mean they should be
ignored by `.gitignore`.

Instead, the repository distinguishes:

- tracked generated package/runtime surfaces that are part of the source tree
- ignored local or diagnostic build outputs such as fetched caches, manifests,
  reports, and generated website output

This distinction is architectural and should not be blurred by trying to infer
ownership from whether a file is handwritten.

## Clean-state consequences

Because tracked generated surfaces are part of the repository, running
`clean` or `distclean` can leave the worktree in a temporarily noisy state
with many tracked files shown as deleted.

This is expected and does not imply that those files belong in `.gitignore`.

Treat these states as **transient workflow states**, not as desired commit
states. If work stops after `clean` or `distclean` and you are not about to
rebuild or intentionally commit regenerated outputs, restore the tracked
generated surfaces from `HEAD` before committing or switching context.

---

# Handwritten Source Directories

Agents and developers should generally make changes in handwritten source areas
such as:

- handwritten helper files under `R/`
- `tools/`
- documentation under `projectdocs/`
- tests under `tests/testthat/`
- policy files under `dev/`

Changes to generated behavior should normally be made in:

- generator scripts
- templates
- metadata parsing code
- pruning logic
- build pipeline scripts

---

# Required Workflow

If a generated file appears to need modification, do not patch it directly.

Instead:

1. Identify the generator or build step that produced the file.
2. Modify the relevant source logic.
3. Regenerate outputs.
4. Run validation checks and tests.
5. Inspect the regenerated output.

---

# File Headers

Generated files should include a clear header stating that they are
automatically generated and must not be edited directly.

This warning should be inserted by the generator itself.

---

# Build Manifests vs Generated Package Files

The shiny.webawesome project distinguishes between **generated package files**
and **build manifests**.

Generated package files are source artifacts that become part of the R package
itself (for example wrapper functions, bindings, or other generated code).

Build manifests, in contrast, are **diagnostic artifacts** produced during the
build process to describe the relationship between upstream metadata and the
generated package.

These manifests are written to:

```text
manifests/report/
```

They are used by the reporting stage of the build pipeline to evaluate upstream
coverage and API conformance.

Because manifests are build diagnostics rather than package assets, they are
**not bundled with the package** and are fully regenerable from the upstream
metadata and repository policy inputs.

---

# Summary

When working in this repository:

- do not edit generated files directly
- modify generator or pipeline logic instead
- regenerate outputs after source changes
- inspect generated outputs, but do not patch them manually
