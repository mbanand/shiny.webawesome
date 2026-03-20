# Architecture Decisions

This document records the **major architectural decisions** made during the design of the `shiny.webawesome` package.

These decisions define the constraints under which the system is implemented. They should be treated as **authoritative design rules** for the project.

Coding agents and developers should not change these decisions without explicitly updating this document.

---

# API Design Philosophy

## Decision

The R interface mirrors the Web Awesome API as closely as possible.

## Rationale

Web Awesome already provides well-designed component APIs and documentation. Mirroring the upstream API allows developers to use Web Awesome documentation directly when writing Shiny applications as well.

## Implementation Rules

* Component names become R functions with the prefix `wa_`.

Example:

```r
wa_button()
wa_select()
wa_dialog()
```

* HTML attributes become R arguments.
* Attribute names convert from kebab-case to snake_case.

Example:

```text
max-options-visible → max_options_visible
```

* Boolean attributes map to logical arguments.
* Enum attributes map to R character arguments validated against allowed values.

---

# Component Metadata Source of Truth

## Decision

The component metadata file

```text
custom-elements.json
```

is the canonical source for component definitions.

## Rationale

The Web Awesome distribution includes `custom-elements.json`, which describes every Web Component and its interface.

Using this file allows the package to automatically generate wrappers and remain synchronized with upstream Web Awesome releases.

## Implementation Rules

* The generator reads metadata from `custom-elements.json`.
* The file is stored in:

```text
inst/extdata/webawesome/
```

* The component metadata is used only during generation, is **not served to browsers**, and is excluded from the built package via `.Rbuildignore`.

---

# Generator-Based Architecture

## Decision

Component wrappers are generated automatically from metadata.

## Rationale

Web Awesome includes dozens of components with large and evolving APIs. Maintaining wrappers manually would be error-prone and difficult to keep synchronized with upstream releases.

A generator-based system allows:

* automatic wrapper generation
* automatic documentation generation
* automatic binding generation
* easy regeneration when Web Awesome updates

## Implementation Rules

The generator produces:

* R wrapper functions
* Shiny input bindings
* update functions
* documentation

Generated files are written to:

```text
R/
inst/bindings/
```

---

# Manual Override Layer

## Decision

The package is **generator-first**, but allows a small manual override layer for components that require specialized behavior.

## Rationale

Most component wrappers can be generated automatically from Web Awesome metadata. However, some components may require adjustments that cannot be represented directly in the generator schema or templates.

Examples may include:

- complex event behavior
- special Shiny integration logic
- compatibility fixes
- upstream component edge cases

Providing a formal override mechanism prevents developers from needing to edit generated files directly.

## Implementation Rules

- Generated code remains the default implementation.
- Manual overrides are used only when necessary.
- Generated files should not be edited directly.
- Overrides are implemented in designated locations defined by the package structure.
- The override layer should remain small and explicit.

---

# Runtime Asset Bundling

## Decision

A **pruned subset of the Web Awesome runtime** is bundled with the package.

## Rationale

The full Web Awesome npm distribution may larger than CRAN package size limits and not everything in it is needed at runtime.

Therefore the build pipeline extracts only the runtime assets required by the browser.

## Implementation Rules

Runtime assets are stored in:

```text
inst/www/webawesome/
```

The pruned runtime bundle includes:

* component modules
* runtime chunks
* CSS styles
* runtime utilities
* localization files

The pruned runtime bundle excludes:

* TypeScript declaration files
* development tooling
* React integrations
* server-side rendering loaders
* editor metadata files
* development documentation

---

# Loader-Based Runtime Model

## Decision

The package uses the Web Awesome loader:

```text
webawesome.loader.js
```

rather than the monolithic runtime entry.

## Rationale

The loader dynamically loads component modules when they appear in the DOM.

Benefits:

* components load lazily
* smaller initial runtime
* better compatibility with Shiny's dynamic UI rendering

## Implementation Rules

The runtime bootstrap process is:

1. `wa_dependency()` loads a bootstrap script.
2. The bootstrap script initializes the Web Awesome base path.
3. The bootstrap script loads `webawesome.loader.js`.
4. The loader registers Web Awesome components dynamically.

---

# Dependency Attachment Strategy

## Decision

Each component wrapper attaches the Web Awesome dependency unless dependency attachment is temporarily disabled.

## Rationale

Web Awesome components should work inside any Shiny layout, including:

```r
fluidPage()
semanticPage()
```

Automatically attaching dependencies ensures that components work without requiring a special page wrapper.

## Implementation Rules

* Each wrapper calls a helper that attaches the dependency.
* The helper checks an option to determine whether dependency attachment is currently enabled.

Example behavior:

Normal usage:

```r
fluidPage(
  wa_button("Click")
)
```

Dependency attached automatically.

Page-level usage:

```r
wa_page(
  wa_button("Click")
)
```

In this case `wa_page()` attaches the dependency once and disables wrapper-level attachment during page construction.

---

# Page Construction Helper

## Decision

The package provides a page constructor:

```r
wa_page()
```

## Rationale

This allows developers to create full Web Awesome-based pages without mixing other layout frameworks.

## Implementation Rules

`wa_page()`:

* temporarily disables per-component dependency attachment
* constructs the page content
* attaches the Web Awesome dependency once
* optionally integrates with Bootstrap layouts

---

# Testing Strategy

## Decision

Testing is performed using a **two-layer test strategy**.

## Rationale

Different aspects of the system require different kinds of testing.

Unit tests verify wrapper correctness, while browser tests verify runtime behavior.

## Implementation Rules

### Layer 1: Unit tests

Use:

```text
testthat
```

to verify:

* wrapper output
* attribute mapping
* argument validation
* dependency attachment behavior

These tests run on CRAN.

---

### Layer 2: Functional tests

Use:

```text
shinytest2
```

to run automated browser tests that:

* launch Shiny apps
* interact with components
* verify events and reactive values
* verify `update_wa_*()` behavior

These tests run in development and CI but are skipped on CRAN.

---

# Development Workflow

## Decision

The package build process follows a deterministic pipeline.

## Rationale

Because large parts of the package are generated automatically, the build process must be reproducible.

## Implementation Rules

The development workflow is:

```text
clean → fetch → prune → generate → test → report
```

Where:

* `clean` removes generated artifacts
* `fetch` downloads a pinned Web Awesome release
* `prune` constructs the runtime bundle
* `generate` builds wrappers and bindings
* `test` validates the system
* `report` generates manifests and reports

Detailed workflow documentation is located in:

```text
docs/workflow/build-pipeline.md
```

---

# Summary

The architectural decisions for `shiny.webawesome` emphasize:

* automatic wrapper generation
* minimal runtime bundling
* close alignment with Web Awesome APIs
* compatibility with existing Shiny layouts
* reproducible builds
* robust automated testing

These principles guide the implementation of the package and should remain stable as the project evolves.
