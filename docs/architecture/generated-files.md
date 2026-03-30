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
- `manifests/`
- `reports/`

These files should not be edited directly.

Depending on the build workflow, generated or derived runtime assets may also
exist under:

- `inst/www/wa/`

Runtime assets should not be manually edited unless the intended change is to
the pruning or bundling logic.

---

# Handwritten Source Directories

Agents and developers should generally make changes in handwritten source areas
such as:

- handwritten helper files under `R/`
- `tools/`
- documentation under `docs/`
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
