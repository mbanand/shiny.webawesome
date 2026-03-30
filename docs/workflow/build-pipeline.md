# Build Pipeline

This document describes the **development workflow used to build and update the `shiny.webawesome` package**.

Because large portions of the package are **generated automatically**, development follows a structured pipeline that ensures the repository remains reproducible and synchronized with upstream Web Awesome releases.

---

# Pipeline Overview

The development pipeline follows this sequence:

```text
clean → fetch → prune → generate → test → report
```

Each stage has a single responsibility and produces outputs that are consumed
by the next stage.

| Stage | Purpose |
|------|--------|
| **clean** | Remove previous build artifacts and generated outputs |
| **fetch** | Retrieve the upstream Web Awesome distribution |
| **prune** | Remove upstream assets not needed by the package |
| **generate** | Generate wrappers and bindings from upstream metadata |
| **test** | Verify runtime behavior of generated components |
| **report** | Generate manifests and verify coverage and API conformance |

This separation ensures that **generation** and **verification** remain
independent concerns.

Generation scripts produce deterministic artifacts from upstream metadata,
while the reporting stage analyzes those artifacts to evaluate coverage and
conformance.

In addition to the main stage outputs, the pipeline also maintains a small
stage-to-stage integrity-record chain used as a developer aid:

- `prune` records checksums for its owned output surface
- `generate` compares its current input surface against prune's record and
  warns on drift, then records checksums for its own generated surface
- `report` compares its current generated-surface input against generate's
  record and warns on drift
- a dedicated final integrity-check tool reruns those comparisons and fails if
  required records are missing or mismatched

This allows developers to continue through intermediate local debug states
while still enforcing a hard integrity gate at the end of the package build
workflow.

---

# Step 1: Clean

The clean step removes generated artifacts and runtime bundles produced during previous builds.

This ensures that subsequent pipeline steps run on a clean repository state.

The clean tool is implemented as:

```text
tools/clean_webawesome.R
```

Two levels of cleaning are supported.

---

## Clean

Removes generated artifacts created during the build process.

Examples include:

* generated R wrapper files
* generated update functions
* generated Shiny bindings
* copied generation metadata under `inst/extdata/webawesome/`
* pruned Web Awesome runtime bundle

Typical directories removed:

```text
generated component files under R/
inst/bindings/
inst/extdata/webawesome/
inst/www/wa/
manifests/
reports/
```
---

## Distclean

Performs a deeper cleanup.

In addition to the normal clean operations, it also removes the cached upstream Web Awesome distribution and build-only metadata copies.

Example directory removed:

```text
vendor/webawesome/
inst/extdata/webawesome/
```

Distclean is useful when rebuilding the package from a fresh upstream download.

---

# Step 2: Fetch

The fetch step downloads a **specific version of Web Awesome** from npm.

This step ensures the build process uses a pinned upstream version.

The fetch tool is implemented as:

```text
tools/fetch_webawesome.R
```

Typical responsibilities include:

* downloading Web Awesome via npm
* using the version pinned in `dev/webawesome-version.txt` by default, unless a version override is supplied
* extracting the fetched npm package in a temporary working directory
* copying the preferred browser-ready upstream runtime tree into the repository
* recording the upstream version

The upstream files are stored in:

```text
vendor/webawesome/
```

Example structure:

```text
vendor/webawesome/
  3.3.1/
    dist-cdn/
    VERSION
```

The repository retains the fetched browser-runtime input under
`vendor/webawesome/<version>/dist-cdn/`.

Fetch requires the upstream npm package's browser-ready `dist-cdn/` tree and
copies it into this repository path. The full downloaded npm package is
treated as a temporary fetch artifact and is discarded after extraction.

The pinned default fetch version is stored in:

```text
dev/webawesome-version.txt
```

This directory contains the fetched upstream runtime input for that specific
version.

It is used as the source for runtime pruning.

---

# Step 3: Prune

The Web Awesome npm distribution contains files that are not required for browser runtime.

The prune step constructs a **minimal runtime bundle** suitable for inclusion in the R package.

The pruning tool is implemented as:

```text
tools/prune_webawesome.R
```

The pruner performs tasks such as:

* copying runtime JavaScript modules
* copying required CSS files
* copying `custom-elements.json` and version metadata for downstream generation
* removing development artifacts
* removing TypeScript declaration files
* removing editor integration files
* removing framework integrations (such as React)
* validating that the fetched upstream bundle contains the required prune inputs
* failing if prune-owned output locations already contain content

The resulting runtime bundle is written to:

```text
inst/www/wa/
```

Example structure:

```text
inst/www/wa/
  webawesome.loader.js
  webawesome-init.js
  components/
  chunks/
  styles/
  utilities/
  translations/
```

As part of prune, the stage also writes an integrity record to:

```text
manifests/integrity/prune-output.yaml
```

That record covers the prune-owned output surface:

- `inst/extdata/webawesome/`
- `inst/www/wa/`

The handwritten package bootstrap file `inst/www/webawesome-init.js` is not
part of this surface because it is not produced by prune.

---

## Runtime Reachability Analysis

The pruner performs **import graph analysis** on JavaScript and CSS files.

This analysis walks the import graph starting from the Web Awesome loader and
the retained runtime entry directories and records which files are reachable
through module imports.

The purpose of this analysis is to:

* detect unused files included in the bundle
* detect missing dependencies
* assist developers when refining pruning rules

If the analysis discovers that a referenced runtime file is missing from the
fetched upstream bundle, prune fails with a clear diagnostic error.

If the analysis discovers present but unreached runtime files, prune does not
fail; those files are recorded in the prune report for inspection.

The analysis produces versioned **diagnostic reports** under:

```text
reports/prune/<version>/
```

Typical outputs include:

```text
reports/prune/<version>/
  summary.md
  reachability.md
```

Pruning decisions remain explicit in the pruning script.

---

# Step 4: Generate

The generate step converts Web Awesome metadata into R code and Shiny bindings.

The generator reads component metadata from:

```text
inst/extdata/webawesome/custom-elements.json
```

This metadata copy is retained in the repository for generation but excluded
from the built package via `.Rbuildignore`.

The generator is implemented as:

```text
tools/generate_components.R
```

The generator performs several tasks.

---

## Component Schema Construction

The component metadata is converted into an intermediate **component schema** that describes:

* component names
* attributes
* properties
* events
* slots

This schema normalizes the Web Component metadata into a format suitable for R code generation.

---

## Manual Override Application

During generation the system may apply **manual override rules** for specific components.

Overrides allow the project to adjust behavior when a component cannot be fully represented by the generator schema.

Typical override situations include:

* component-specific Shiny integration behavior
* special event handling
* compatibility fixes for upstream components
* support-model overrides when upstream metadata does not fully expose the
  Shiny-relevant interaction contract of a component

Overrides are intentionally limited and should remain small relative to the generated codebase.

Overrides are applied during generation so that the **final output remains deterministic and reproducible**.

When possible, these overrides should be expressed as narrow handwritten policy
inputs under `dev/` rather than as broad hard-coded exceptions scattered
through generator code. For example, a binding override policy may explicitly
mark a component as action-bound when the component semantically mirrors a
native control but the relevant event is not declared in upstream metadata.

The override mechanism and its locations are defined in:

```text
docs/architecture/package-structure.md
```

---

## Wrapper Generation

The generator produces R wrapper functions for each Web Awesome component.

Generated files are written to:

```text
R/
```

Example output:

```text
R/
  wa_button.R
  wa_select.R
  wa_input.R
```

---

## Update Function Generation

Interactive components receive generated update functions.

Generated files are also written under top-level `R/`, typically in the same
file as the corresponding wrapper when that keeps a component API together.

Example:

```text
wa_select.R
wa_input.R
```

---

## Shiny Binding Generation

JavaScript bindings are generated for components that interact with Shiny inputs.

The default generated support model is a **value-oriented input binding** that
subscribes to a supported value/commit event and then reads the component's
current value.

In rare cases, generation may instead emit an **action-oriented binding** when
an explicit policy input declares that the component should behave like a
Shiny action input despite incomplete upstream metadata.

A second rare policy-driven exception is an **action-with-payload binding**,
where the main Shiny input remains action-oriented but a companion input
publishes the latest committed payload state. This is used for split
contracts such as `wa-dropdown`, where repeated same-item selections should
still invalidate Shiny even when the latest payload value does not change.

Generated files are written to:

```text
inst/bindings/
```

Example:

```text
wa_select.js
wa_input.js
```

Before generation writes outputs, the stage compares the current prune-owned
input surface against `manifests/integrity/prune-output.yaml` and emits an
advisory warning if the record is missing or the surface has drifted. After
generation completes, it writes its own integrity record to:

```text
manifests/integrity/generate-output.yaml
```

The generate-owned integrity surface currently includes:

- generator-owned top-level `R/*.R` files
- `inst/bindings/*.js`

---

# Step 5: Test

After generation completes, the package is validated using automated tests.

Testing occurs in two layers.

---

## Unit Tests

Unit tests verify wrapper correctness and argument handling.

Tests include checks for:

* correct HTML tag generation
* attribute name conversion
* argument validation
* dependency attachment

These tests are implemented using:

```text
testthat
```

and stored in:

```text
tests/testthat/
```

---

## Functional Tests

Functional tests validate runtime behavior inside a browser.

These tests use:

```text
shinytest2
```

Functional tests:

* launch small Shiny applications
* interact with components
* verify reactive values
* verify event propagation
* verify `update_wa_*()` behavior

These tests run during development and CI.

They are skipped on CRAN.

---

# Step 6 — Report (Coverage and Conformance)

The **report** stage performs coverage and conformance verification against
upstream metadata.

Unlike the **test** stage, which validates runtime behavior of the generated
package, the report stage verifies that the package surface remains aligned
with the upstream Web Awesome component API.

This stage analyzes the outputs produced by the generation stage and produces
diagnostic reports describing the package's level of upstream coverage.

---

## Objectives

The report stage answers four key questions:

1. **Generated File Integrity**

    - Do all expected generated files exist?
    - Are any generated files missing or unexpected?

2. **Upstream Component Coverage**

    - Which upstream components exist in `custom-elements.json`?
    - Which components are implemented by the package?
    - Which are planned, excluded, or currently unsupported?

3. **Component API Conformance**

    - For implemented components, do the wrapper, binding, update, and export
      artifacts required by the selected support model exist?
    - Do the generated wrapper arguments, update-helper parameters, binding
      selector/name registration, subscribed events, and mode-specific binding
      behaviors match the current generator rules?
    - Which components currently need deeper per-component API review beyond
      that generated-surface conformance layer?

4. **Manual API Inventory**

    - Which exported package APIs are not derived from upstream components?
    - Are these APIs intentionally maintained?

---

## Reporting Outputs

The report stage produces both **machine-readable manifests** and
**human-readable summaries**.

Structured manifests are written to:

```text
manifests/report/
```

Manifests are generated from:

- upstream metadata (`custom-elements.json`)
- discovered generated outputs
- a small human-maintained policy file describing intentional exclusions or plans

Human-readable reports are written to:

```text
reports/report/
```

Typical output may include:

- total upstream components
- number of fully supported components
- components partially implemented
- components not yet implemented
- components intentionally excluded

Additional checks may report:

- missing wrapper functions
- missing expected bindings or update functions
- undocumented manual APIs

These outputs make the current state of upstream coverage transparent and
allow continuous integration to detect upstream changes quickly.

Before writing manifests and reports, the report stage compares the current
generate-owned surface against `manifests/integrity/generate-output.yaml`.
This comparison is advisory at the stage level and warns when the record is
missing or the surface has drifted.

## Final Integrity Gate

The package build workflow also includes a dedicated integrity-check tool that
reruns the prune-to-generate and generate-to-report comparisons and fails on:

- missing required integrity records
- file-set mismatches
- per-file digest mismatches
- tree-digest mismatches

This final gate is intended to catch incomplete local rebuilds or accidental
manual edits before the overall package build is treated as successful.

In addition to its CLI output, the final integrity gate writes a short
human-readable summary to:

```text
reports/integrity/summary.md
```

The summary is written on both pass and fail so developers can inspect the
current prune-output and generate-output comparisons even when the gate stops
the build.

---

## CI Behavior

The report stage may optionally enforce policy in continuous integration.

For example:

- fail if an upstream component disappears from the coverage manifest
- fail if a component marked `covered` has no generated wrapper
- warn if upstream components exist that are not categorized

These checks ensure that upstream changes are detected quickly and that the package's coverage status remains transparent.

---

# Typical Development Workflow

The full development cycle typically follows these commands:

```text
clean_webawesome()
fetch_webawesome()
prune_webawesome()
generate_components()
review_binding_candidates()
devtools::test()
devtools::check()
devtools::document()
```

This sequence rebuilds the entire package from upstream metadata and verifies the resulting implementation.

The top-level `build_package.R` orchestrator currently inserts an advisory
binding-candidate review step between generate and report:

```text
fetch → prune → generate → review_binding_candidates → report → check_integrity
```

This review step writes a human-readable diagnostic report under
`reports/review/` and is intended to surface components whose interaction
semantics may deserve manual follow-up. It remains advisory in meaning: a
non-empty candidate list does not by itself fail the build, but a real tool
execution failure still stops the orchestrator.

Before `generate_components()` exists and produces a real package surface,
`build_package.R` should remain limited to the currently implemented package
stage scripts rather than trying to run package-level `devtools::*`
validation prematurely.

Once generation is implemented, package-level validation should be added to
`build_package.R` as separate top-level orchestration steps rather than as one
combined "package generation" action. Typical steps are:

- `Documenting package` via `devtools::document()`
- `Testing package` via `devtools::test()`
- `Checking package` via `devtools::check()`

These steps should support explicit skip flags, and `devtools::check()` should
be treated as the heaviest optional local gate.

---

# Updating Web Awesome

When Web Awesome releases a new version, the update process is:

1. Run `distclean`.
2. Fetch the new upstream version.
3. Prune the runtime bundle.
4. Regenerate wrappers and bindings.
5. Run the test suite.
6. Generate manifests and reports.

Because the package is generator-driven, updating to new upstream versions is typically straightforward.

---

# Summary

The build pipeline ensures that `shiny.webawesome` remains reproducible and synchronized with Web Awesome.

The pipeline:

* downloads upstream releases
* constructs a minimal runtime bundle
* generates wrappers and bindings
* validates the resulting package
* generates reports

By following this pipeline, the entire package can be rebuilt automatically from upstream metadata.
