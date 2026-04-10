# Build Pipeline

This document describes the **development workflow used to build and update the `shiny.webawesome` package**.

Because large portions of the package are **generated automatically**, development follows a structured pipeline that ensures the repository remains reproducible and synchronized with upstream Web Awesome releases.

---

# Pipeline Overview

The development and release pipeline follows this sequence:

```text
clean → fetch → prune → generate → test → report → finalize → publish
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
| **finalize** | Run late-stage release-preparation validation, rebuild declared derived artifacts, and write a release handoff record |
| **publish** | Verify the finalize handoff, create release state in git, and deploy the already-built website |

This separation ensures that **generation**, **verification**, **release
preparation**, and **publishing** remain distinct concerns.

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

The late stages have intentionally different responsibilities:

- `report` produces deterministic coverage, conformance, and integrity
  diagnostics about the generated package state
- `finalize` performs the recurring late-stage local release-preparation gate
  and writes a machine-readable handoff record for publishing
- `publish` is a separate explicit maintainer-invoked release action that
  consumes the finalize handoff, verifies that the repo state still matches
  it, and then performs external release actions such as git tagging,
  pushing, and website deployment

CRAN submission remains outside this tooling. A successful `publish` run means
the package is ready for the maintainer to decide whether to submit it.

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
* generated website output under `website/`

Typical directories removed:

```text
generated component files under R/
inst/bindings/
inst/extdata/webawesome/
inst/www/wa/
manifests/
reports/
website/
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

Prune also writes a small shipped package metadata file to:

```text
inst/SHINY.WEBAWESOME_VERSION
```

That file records the bundled upstream Web Awesome version for installed
package helpers and other package-level runtime introspection.

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
- `inst/SHINY.WEBAWESOME_VERSION`
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

Schema construction may also perform maintainer-facing validation when
upstream metadata appears insufficient to describe constructor-time behavior
reliably. In particular, attribute typing should be reviewed for potential
metadata/runtime mismatches, especially when:

* metadata heuristics suggest different attribute and property semantics
* vendored runtime code indicates custom attribute/property conversion
* constructor-time HTML emitted by the package may differ from runtime
  property semantics

Detection does not need to rely on a single signal. Multi-stage approaches are
appropriate here, such as using metadata heuristics to flag suspicious fields
and implementation-based inspection of vendored runtime code to confirm them.

When a confirmed mismatch affects constructor-time wrapper emission, the
generator should fail loudly rather than silently emit ambiguous or incorrect
HTML.

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
* attribute constructor-serialization overrides when upstream metadata and
  runtime implementation disagree in ways that would otherwise make generated
  wrapper HTML incorrect or ambiguous

Overrides are intentionally limited and should remain small relative to the generated codebase.

Overrides are applied during generation so that the **final output remains deterministic and reproducible**.

When possible, these overrides should be expressed as narrow handwritten policy
inputs under `dev/` rather than as broad hard-coded exceptions scattered
through generator code. For example, a binding override policy may explicitly
mark a component as action-bound when the component semantically mirrors a
native control but the relevant event is not declared in upstream metadata.
Likewise, an attribute override policy may explicitly define how specified R
wrapper values serialize into emitted HTML attributes when upstream runtime
behavior cannot be represented safely by metadata typing alone.

These override paths are intended to complement generator validation, not
replace it. Detection should happen first; once a mismatch is confirmed, the
generator should require an explicit policy entry before generation can
proceed.

The override mechanism and its locations are defined in:

```text
projectdocs/architecture/package-structure.md
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

# Step 7: Finalize

The finalize step is the recurring late-stage local release-preparation gate.

It is intended to be explicit and reviewable rather than a hidden side effect
of another stage. The finalize stage is expected to be integrated into the
top-level `build_package.R` orchestrator, while still remaining a distinct
named stage with its own contract.

The finalize tool is implemented as:

```text
tools/finalize_package.R
```

Unlike earlier validation-only stages, finalize is allowed to update declared
derived artifacts. Typical finalize-owned outputs include:

- package documentation regenerated by `devtools::document()`
- the built pkgdown site under `website/`
- the package tarball produced by `devtools::build()`
- machine-readable and human-readable finalize handoff artifacts

Finalize should not be treated as permission to make opportunistic edits to
handwritten source inputs. Its role is to validate release readiness and
rebuild declared derived artifacts from the existing source tree.

## Finalize Modes

Finalize supports two operating modes:

- default mode, which is suitable for iterative late-stage development and may
  continue past selected non-fatal validation findings while recording them
- `--strict`, which is intended for release preparation and fails on any
  required release gate

The top-level `build_package.R` orchestrator should expose a corresponding
strict mode such as `--finalize-strict` when wiring this stage into the full
package workflow, and should pass through the external confirmation flags
needed by `finalize --strict`.

## Strict Build Preconditions

The top-level `build_package.R --finalize-strict` orchestration should own the
clean release-build starting-state requirement.

Before the full package-build pipeline begins, strict `build_package` should
fail early if the repository already contains stale or mismatched stage-owned
build surfaces that indicate the release build is not starting from a
trustworthy local state. In practice this means the strict run should not
silently trust pre-existing vendor-owned, prune-owned, or generate-owned
artifacts that do not match the current build chain.

The failure message should direct the developer to start from a cleaner state,
typically by running `distclean` or otherwise rebuilding from a clean tree.

`finalize --strict` itself should not repeat this clean-start assertion. It is
the late-stage validation gate within the already-running strict
`build_package` orchestration, and therefore should operate on the rebuilt
surfaces produced by the earlier stages of that orchestrator.

## Finalize Sequence

The finalize stage should run the following steps in order:

1. remove any stale finalize handoff artifacts so later checks cannot
   accidentally reuse them
2. run the integrity gate via `check_integrity`
3. run non-mutating style and lint checks for package code, tooling code, and
   handwritten JavaScript
4. run dependency-audit checks without auto-editing `DESCRIPTION`
5. regenerate package documentation with `devtools::document()`
6. run `devtools::test()`
7. compute advisory package test coverage and record the reported percentage
   in the finalize artifacts without treating it as a release gate
8. build the local pkgdown website with `build_site.R`, including local
   website link auditing via `lychee`
9. audit package-source URLs without auto-updating them; package-owned
   website URLs should be validated against the built local `website/`
   artifact rather than the live domain
10. run `devtools::check()`
11. in strict mode, require explicit maintainer confirmation flags for the
   external pre-release checks and final visual review:
   `--confirmed-rhub-pass` and `--confirmed-visual-review`
12. build the package tarball with `devtools::build()`
13. write the finalize handoff artifacts

Default-mode finalize may continue past selected non-fatal validation findings
and record them as warnings. Strict finalize should fail on any required gate.

## Release-Audit Checks in Finalize

The finalize stage owns the local release-audit checks that can be run
deterministically from the repository itself. These include:

- the final integrity gate
- dry-run style and lint checks
- dependency audits
- package documentation regeneration
- local website link auditing during site build
- package-source URL audits
- package tests
- advisory package test coverage reporting
- site build validation
- `devtools::check()`
- package tarball creation

Two release-oriented checks remain outside the automatic finalize execution
path because they are external or maintainer-judgment workflows:

- `rhub` or equivalent external pre-release checks
- a final human visual review of a representative Shiny application, launched
  locally with `./tools/check_interactive.R`

In default mode, finalize should print explicit next-step instructions for
those checks. In strict mode, finalize should require the maintainer to supply
`--confirmed-rhub-pass` and `--confirmed-visual-review`; if either
confirmation is absent, strict finalize fails early.

## Finalize Handoff Artifacts

Finalize writes its handoff artifacts to:

```text
manifests/finalize/
reports/finalize/
```

The machine-readable handoff record should be written to:

```text
manifests/finalize/release-handoff.yaml
```

and a short human-readable summary should be written to:

```text
reports/finalize/summary.md
```

The handoff record should include, at minimum:

- the package version
- the git `HEAD` commit
- whether finalize ran in default or strict mode
- the built package tarball path and checksum
- the built `website/` tree path and checksum
- the advisory package test coverage result, when available
- a checksum for the tracked git tree at `HEAD`
- a timestamp
- a pass/warn/fail summary

The tracked-tree checksum should be derived from git's tracked repository
state rather than from the raw filesystem so that ignored files do not create
false drift.

---

# Step 8: Publish

The publish stage is a separate explicit maintainer-invoked release action.

It should remain distinct from `build_package.R` because publishing changes
external release state and should happen only when the maintainer explicitly
decides the repository is ready to put out.

Publish should be exposed as a dedicated CLI tool with explicit action flags.
At minimum, it should support:

- `--release-version <version>` as a required maintainer-supplied input
- `--dry-run` for verification-only readiness checks
- `--do-tag` to create and push the release tag and current branch
- `--deploy-site` to deploy the already-built `website/` tree

Publish should not modify package source inputs or rebuild package artifacts.
Its job is to verify the finalize handoff and then, when explicitly requested
by the maintainer, carry out one or both external release action groups.

## Publish Inputs and Preconditions

Publish should require:

- a `--release-version` CLI argument supplied by the maintainer
- at least one explicit action selection:
  `--dry-run`, `--do-tag`, or `--deploy-site`
- an existing finalize handoff record
- a clean git working tree
- the current `HEAD` commit matching the handoff record
- no drift in the tracked git tree, built `website/` tree, or built tarball
  relative to the recorded handoff checksums

For real publish actions, publish should additionally require:

- a strict finalize handoff record
- a passing finalize handoff status
- the current branch to be `main`

For `--dry-run`, publish may accept a non-strict finalize handoff or a
handoff with warnings, but it should surface those conditions clearly as
warnings rather than executing any external release actions.

Publish should validate that the requested release version:

- matches the package version recorded in `DESCRIPTION`
- matches the release version recorded in `NEWS.md`
- matches the git tag name exactly when tag creation is requested
- does not already exist as a git tag locally
- does not already exist in the remote `origin` repository

## Publish Sequence

The publish stage should run the following steps in order:

1. remove any stale publish-stage report artifacts so the current run writes a
   fresh summary
2. validate the supplied CLI arguments and requested action set
3. validate the supplied `--release-version`
4. load the finalize handoff and verify the recorded handoff and current repo
   state still match
5. verify branch expectations and release-tag readiness
6. verify website deployment readiness when `--deploy-site` is requested,
   including any available wrapper-level credential or configuration checks
7. if `--dry-run` is set, stop after writing publish diagnostics and report
   readiness or blockers without executing external release actions
8. if `--do-tag` is set, create the release git tag
9. if `--do-tag` is set, push the current branch to `origin`
10. if `--do-tag` is set, push the release tag to `origin`
11. if `--deploy-site` is set, deploy the already-built `website/` directory
    using a dedicated repo wrapper script around the Netlify CLI
12. write machine-readable and human-readable publish-stage outputs
13. print a final completion message stating which release actions were
    executed and whether the package is now ready for maintainer-controlled
    CRAN submission

Publish should not rebuild the site itself. It should deploy the `website/`
artifact already produced and verified by finalize.

`--dry-run` should be verification-only even when `--do-tag` or
`--deploy-site` are also supplied. In that mode, publish should report the
requested actions as planned but not executed.

## Main Branch Expectation

The repository should treat the GitHub `main` branch as a branch that should
not be left in a broken state. Local development may pass through intermediate
broken states, but published remote history should not.

Accordingly, real publish actions should require the current branch to be
`main`. A dry run may warn when the branch differs so maintainers can inspect
readiness before switching branches.

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

For late-stage release preparation, the expected pipeline continues with
finalize and then, if explicitly chosen by the maintainer, publish.

The top-level `build_package.R` orchestrator currently inserts an advisory
binding-candidate review step between generate and report, and is intended to
grow into the recurring package-build orchestrator that ends with finalize:

```text
fetch → prune → generate → review_binding_candidates → report → check_integrity → finalize
```

This review step writes a human-readable diagnostic report under
`reports/review/` and is intended to surface components whose interaction
semantics may deserve manual follow-up. It remains advisory in meaning: a
non-empty candidate list does not by itself fail the build, but a real tool
execution failure still stops the orchestrator.

Package-level validation should be exposed through explicit top-level
orchestration steps rather than being collapsed into one combined "generate
package" action. The release-oriented late-stage work should remain explicit:

- `report` for coverage, conformance, and generated-surface diagnostics
- `finalize` for late-stage release preparation
- `publish` as a separate explicit maintainer-invoked release action

---

# Updating Web Awesome

When Web Awesome releases a new version, the update process is:

1. Run `distclean`.
2. Fetch the new upstream version.
3. Prune the runtime bundle.
4. Regenerate wrappers and bindings.
5. Run the test suite.
6. Generate manifests and reports.
7. Run `build_package --finalize-strict` from a release-build starting point,
   passing the external confirmation flags required by `finalize`.
8. Publish only when the maintainer explicitly decides to create the release.

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
* performs an explicit late-stage finalize gate
* leaves publish and CRAN submission as separate maintainer decisions

By following this pipeline, the entire package can be rebuilt automatically from upstream metadata.
