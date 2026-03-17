# AGENTS.md

This file provides **operational guidance for coding agents** working in the `shiny.webawesome` repository.

The repository contains extensive documentation describing the system architecture and development workflow. Agents should consult those documents before making changes.

---

# Project Overview

`shiny.webawesome` provides a complete **R/Shiny interface to the Web Awesome component library**.

The package exposes Web Awesome components as R functions that generate Web Component HTML tags and connect them to Shiny's reactive system.

The project is **generator-driven**:

* component wrappers are generated from Web Awesome metadata
* Shiny bindings are generated automatically
* runtime assets are bundled from the upstream Web Awesome distribution

Agents should **not attempt to re-design the architecture** of the project.

---

# Authoritative Documentation

The following documents define the architecture, workflow, and development
infrastructure of the project.

Agents should read them before making modifications.

```text
docs/README.md

docs/architecture/overview.md
docs/architecture/decisions.md
docs/architecture/package-structure.md
docs/architecture/generated-files.md
docs/architecture/api-coverage-and-conformance.md

docs/development/manifests.md
docs/development/component-coverage.md

docs/workflow/build-pipeline.md
docs/workflow/agent-development-playbook.md

docs/testing/testing-strategy.md
```

These files are the **source of truth** for:

- repository structure
- generator behavior
- runtime loading model
- coverage and conformance tracking
- development workflow
- testing strategy

If implementation changes require architectural changes, the documentation
should be updated first.

For task execution practices, scoping, regeneration discipline, validation flow,
and uncertainty handling, see:

`docs/workflow/agent-development-playbook.md`

Generated files must not be edited directly. See:

`docs/architecture/generated-files.md`

For rules governing generated file integrity, upstream component coverage,
API conformance, and handwritten package API inventory, see:

`docs/architecture/api-coverage-and-conformance.md`

---

# Key Architectural Principles

The project follows several important principles.

## Generator-First Architecture

Component wrappers and bindings are generated automatically from Web Awesome metadata.

Agents should prefer **improving the generator** rather than manually modifying generated code.

Generated code lives in:

```
R/generated/
R/generated_updates/
inst/bindings/
```

Generated files should **not be edited directly**.

---

## Manual Override Layer

The project supports a **small manual override layer** for edge cases.

Overrides may be implemented when generator logic cannot fully represent a component.

However:

* overrides should remain minimal
* overrides must not modify generated files directly
* generator improvements should be preferred whenever possible

Details are documented in:

```
docs/architecture/package-structure.md
```

---

## Runtime Bundling

Web Awesome runtime assets are bundled with the package after being **pruned from the upstream distribution**.

Runtime files live in:

```
inst/www/webawesome/
```

The upstream distribution is stored in:

```
vendor/webawesome/
```

Agents should **not manually modify runtime assets** unless adjusting the pruning logic.

---

# Development Workflow

The project uses a deterministic build pipeline.

```
clean → fetch → prune → generate → test → report
```

Typical development commands:

```
clean_webawesome()
fetch_webawesome()
prune_webawesome()
generate_components()
```

These scripts live in:

```
tools/
```

In addition, R package development tools are also used:

```
devtools::test()
devtools::check()
devtools::document()
```

Agents should follow this workflow when modifying generator logic or updating Web Awesome.

---

# Build Manifests and Reporting

The build pipeline generates structured **manifests** describing the relationship
between upstream Web Awesome components and the generated package.

These manifests are written to:

```text
manifests/
```

Examples include:

- `generated-file-manifest.yaml`
- `component-coverage.yaml`
- `component-api-conformance.yaml`
- `manual-api-inventory.yaml`

These files are **generated artifacts** and should not be edited manually.

They are consumed by the reporting stage of the build pipeline, which produces
human-readable diagnostic reports written to:

```text
report/
```

These reports summarize:

- upstream component coverage
- API conformance
- generated file integrity
- manually implemented package APIs

Agents should rely on these manifests and reports when evaluating whether the
package fully supports the upstream Web Awesome API.

Do **not assume completeness solely from the presence of generated files**.

---

# Testing Requirements

The project uses a **two-layer testing strategy**.

## Unit tests

Implemented with:

```
testthat
```

These verify wrapper generation and argument handling.

---

## Functional tests

Implemented with:

```
shinytest2
```

These verify browser behavior and Shiny integration.

Functional tests are skipped on CRAN but run during development and CI.

Details are documented in:

```
docs/testing/testing-strategy.md
```

---

# Rules for Coding Agents

When modifying this repository, agents must follow these rules.

1. **Do not edit generated files directly.**

2. Prefer modifying:

    * generator scripts
    * templates
    * schema logic

3. Follow the documented build pipeline.

4. Run the relevant documented checks after making changes. This includes:

    - the documented build pipeline
    - unit and functional tests
    - the reporting step that evaluates coverage and API conformance
    - any applicable lint, style, build, or package validation steps

5. Maintain compatibility with existing Web Awesome APIs.

6. Avoid introducing large new dependencies unless necessary.

7. Keep the runtime bundle minimal.

8. Handwritten R code should follow the Tidyverse style guide, available at https://style.tidyverse.org. 

9. Use `{styler}` for formatting and `{lintr}` for style checks where applicable.

10. This is a CRAN-quality package. Documentation, tests, coding style must all be at that level. Follow details specified in `docs/workflow/agent-development-playbook.md` in this regard.

11. Generated code should be formatted consistently using `{styler}` after generation.

12. Agents should preserve deterministic coverage tracking and conformance checks. Do not infer completeness solely from the presence of generated files.

---

## Package API and Exports

Functions intended for users must be explicitly exported and documented.

Internal helper functions should not be exported.

Agents should follow these rules:

- User-facing functions must include `@export` in their roxygen2 documentation.
- Internal helper functions should not include `@export`.
- Internal helpers should typically start with a leading underscore (e.g. `_parse_metadata()`).
- After modifying exports, run `devtools::document()` to update the NAMESPACE.

Generated wrapper functions should include roxygen2 documentation and `@export` if they are part of the package API.

Avoid exporting helper functions unless they are intentionally part of the public API.

The package API should remain minimal and stable. Prefer keeping most functions internal unless they are clearly intended for users.

---

## Deterministic Output for Generated Files

Generated files must be written in a deterministic order.

When generating multiple functions, bindings, or files:

- Sort component names alphabetically before generating outputs.
- Sort attributes, properties, and events before writing code.
- Avoid relying on iteration order from JSON or filesystem traversal.

Deterministic ordering prevents unnecessary diffs and keeps generated code stable across runs.

---

# Typical Tasks for Agents

Common tasks in this repository include:

* implementing and improving generator logic
* adding support for new Web Awesome components
* implementing or refining build pipeline scripts
* updating to new Web Awesome versions
* refining pruning rules
* implementing or improving tests
* checking and improving test coverage
* improving documentation
* maintaining a journal - refer to `docs/workflow/agent-development-playbook.md` for details

Agents should prefer **systematic solutions** rather than one-off fixes.

---

# When Architecture Changes Are Needed

If a change requires modifying:

* repository structure
* generator architecture
* runtime loading strategy
* testing architecture

then the relevant documentation in `docs/` should be updated before implementing the change.

---

# Summary

Coding agents should treat the repository as a **generator-driven system** with
clear architectural constraints.

Prefer improving generator logic rather than editing generated code.

Follow the documented build pipeline:

```text
clean → fetch → prune → generate → test → report
```

Generated artifacts, manifests, and reports should be treated as deterministic
outputs of the build system.



