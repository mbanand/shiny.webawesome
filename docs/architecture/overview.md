# Architecture Overview

This document describes the **overall architecture of the `shiny.webawesome` package**.

It explains how Web Awesome components are integrated with Shiny, how component wrappers are generated automatically, and how runtime assets are bundled and loaded in Shiny applications.

This file provides the high-level system model. Detailed implementation rules are documented elsewhere.

---

# Project Goal

The goal of `shiny.webawesome` is to provide a **complete and ergonomic interface to the Web Awesome component library for R and Shiny**.

The package exposes Web Awesome components as R functions that generate the corresponding Web Component HTML tags.

Example conceptual mapping.

Web Awesome HTML:

```
<wa-button appearance="filled">Click</wa-button>
```

Shiny wrapper:

```
wa_button("Click", appearance = "filled")
```

The R interface mirrors the Web Awesome API as closely as possible while using standard R conventions such as snake_case argument names.

---

# Design Philosophy

The architecture follows several key design principles.

## Mirror the upstream API

The R interface should mirror the Web Awesome API as closely as possible.

Rules:

* HTML attributes become R arguments
* kebab-case attributes become snake_case
* component names become `wa_*()` functions

Example:

```
max-options-visible → max_options_visible
```

This allows developers to use Web Awesome documentation directly when writing Shiny apps as well.

---

## Generator-driven wrappers

Component wrappers are **generated automatically** from Web Awesome metadata.

The Web Awesome distribution includes a metadata file called:

```
custom-elements.json
```

This file describes all Web Components, including:

* attributes
* properties
* events
* slots

`shiny.webawesome` parses this metadata and generates:

* R component wrappers
* Shiny input bindings
* update functions
* documentation

This approach ensures the R interface stays synchronized with upstream Web Awesome releases.

---

## Thin runtime layer

The package is designed as a **thin wrapper around Web Awesome**.

It does not reimplement component behavior.

Instead it provides:

* R wrappers that emit Web Component tags
* Shiny bindings that interact with those components
* a minimal runtime bundle of Web Awesome assets

The actual component behavior is implemented by Web Awesome in the browser.

---

# System Architecture

The overall architecture consists of five major stages.

1. Web Awesome distribution
2. Runtime pruning
3. Metadata extraction
4. Code generation
5. Shiny runtime integration

The architecture pipeline is:

```
Web Awesome dist
→ prune runtime assets
→ extract component metadata
→ build component schema
→ generate wrappers and bindings
→ run inside Shiny
```

Each stage is described below.

---

# Web Awesome Distribution

Web Awesome is distributed through npm.

The upstream package contains browser/runtime artifacts in `dist-cdn/` plus a
bundler-oriented `dist/` tree.

The browser-ready distribution contains:

* component modules
* shared runtime chunks
* CSS styles
* metadata files
* loader/autoloader utilities

The build pipeline vendors the browser-ready tree into:

```text
vendor/webawesome/<version>/dist-cdn/
```

The upstream npm package's `dist-cdn/` tree is the source for the vendored
browser runtime because it is already rewritten for direct browser loading.

Not all of these files are needed at runtime, and the full distribution is potentially larger than what can be shipped directly in a CRAN package.

Therefore the package build process downloads the upstream distribution and extracts only the runtime assets required for the browser.

---

# Runtime Pruning

A build script (`prune_webawesome.R`) constructs a **minimal runtime bundle** suitable for inclusion in the R package.

The pruner performs several operations:

* copies runtime JavaScript modules
* copies required CSS files
* removes development artifacts
* removes TypeScript declaration files
* removes React integrations and tooling files

The resulting runtime bundle is stored in:

```
inst/www/wa/
```

The component metadata file `custom-elements.json` is copied to:

```
inst/extdata/webawesome/
```

This file is used by the code generator but is not served to browsers.
It is retained in the repository as build input and excluded from the built
package via `.Rbuildignore`.

---

# Component Metadata and Schema

The Web Awesome component metadata file (`custom-elements.json`) is parsed to produce an intermediate **component schema**.

The schema normalizes Web Component metadata into a format suitable for R code generation.

The schema includes:

* component name
* attributes
* properties
* events
* slots
* component classification

This schema is the central data structure used by the generator.

---

# Code Generation

Generator scripts transform the component schema into source code.

The generator produces:

* R component wrapper functions
* Shiny input bindings
* update functions
* documentation
* examples

Templates are used to generate consistent code for all components.

Generated files are written to directories such as:

```
R/
inst/bindings/
```

Because the code is generated, the system can regenerate the entire component API when Web Awesome is updated.

## Manual Override Layer

The package is **generator-first**, but the architecture also permits a small manual override layer for edge cases.

Most Web Awesome components can be generated automatically from metadata. However, some components may require specialized behavior, additional validation, or runtime adjustments that cannot be expressed directly in the generator templates.

For these situations the package provides a mechanism for **manual overrides that coexist with generated code**.

Key principles:

- Generated code remains the default implementation.
- Manual overrides are used only when necessary.
- Overrides are implemented in dedicated locations rather than by editing generated files directly.
- Override policy should be expressed as narrow handwritten build inputs when
  possible, rather than as ad hoc patches to generated outputs.

One concrete use case is **binding support-model overrides** for components
whose Shiny-relevant interaction semantics are not fully represented in
upstream metadata. In such cases, a small handwritten policy layer may declare
that a component should use a specific generated binding mode even when the
upstream `custom-elements.json` file does not expose the needed event
information directly.

The exact structure of this override layer is defined in:

`architecture/package-structure.md`

---

# Runtime Loading Model

At runtime, Web Awesome components are loaded dynamically in the browser.

The package bundles a subset of Web Awesome runtime assets.

These assets include:

* the Web Awesome loader
* component modules
* shared runtime chunks
* CSS styles
* utility modules

When a Shiny page includes a Web Awesome component, the following process occurs.

1. The `shiny.webawesome` R wrapper function that is called generates the corresponding HTML tag.
2. The `shiny.webawesome` dependency initializes the Web Awesome base path and starts the autoloader.
3. The autoloader scans the page for Web Awesome component tags.
4. The autoloader dynamically imports the component module.
5. The browser upgrades the tag into a custom element.
6. Shiny input bindings interact with the component.

This model allows components to be loaded lazily and keeps the runtime bundle efficient.

---

# Dependency Loading Strategy

The Web Awesome runtime dependency must be attached whenever a Web Awesome component is used.

There are two supported usage modes.

## Component-level usage

Components may be used inside existing Shiny layouts such as:

```
fluidPage()
semanticPage()
```

In this case each component wrapper attaches the dependency automatically.

Example:

```
fluidPage(
  wa_button("Click")
)
```

---

## Page-level usage

The package also provides a helper function:

```
wa_page()
```

This function constructs a full page using Web Awesome components.

When `wa_page()` is used, dependency attachment is handled once at the page level.

Component wrappers temporarily disable their own dependency attachment during page construction to avoid redundant work.

---

# Shiny Integration

For interactive components, the generator creates **Shiny input bindings**.

Input bindings connect Web Component properties and events to Shiny's reactive system.

These bindings are intentionally limited to **state-commit, input-value events**
that fit Shiny's reactive input model.

In practice, this means the binding should subscribe to an event that signals
"the component's current input value changed" and then read the component's
current value for delivery to the Shiny server.

The package does **not** treat every upstream Web Awesome custom event as a
Shiny event automatically.

This also means the Shiny-facing binding contract is not always named after
the upstream event that triggered synchronization. When the reactive contract
is inherently action-like, the binding may use action semantics. In rare
cases, a component may instead use action-with-payload semantics, where the
main Shiny input remains action-oriented but a separate companion input
publishes the latest committed payload state. Otherwise, the binding should
expose the durable semantic value implied by the event, typically by reading
a stable upstream property or state field such as `activeSlide`,
`selectedItemIds`, or `open`.

High-frequency or interaction-only events, such as hover telemetry, should
generally remain browser-side and be handled with client-side JavaScript
unless a future design explicitly introduces an opt-in forwarding mechanism.

The default generated binding model is therefore **value-oriented**. However,
the architecture also allows a narrow, explicit policy seam for exceptional
cases where a component should behave like a Shiny **action** input rather than
like a value-bearing input, or like a split **action-with-payload** contract
when repeated same-value selections should still invalidate Shiny while a
companion input exposes the latest committed payload. These exceptional modes
are intended for rare situations where the component's effective interaction
contract is clear, but the upstream metadata does not declare the relevant
native or inherited event in a way the generator can classify automatically.

The current canonical action-with-payload example is `wa-dropdown`, where
`input$<input_id>` is the action-style trigger and
`input$<input_id>_value` is the latest selected item value side channel.

Typical behavior:

* component event triggers change
* Shiny binding reads component value
* value is sent to the Shiny server
* server logic reacts to the new value

For components that support programmatic updates, the generator also creates:

```
update_wa_*()
```

functions.

These functions allow the Shiny server to update the component state in the browser.

---

# Build Manifests and Reporting

The build system produces a set of structured manifests that describe the
relationship between upstream Web Awesome components and the generated
package.

These manifests serve as the foundation for coverage and conformance analysis.

They are generated during the build process and written to:

```text
manifests/
```

Examples include:

- `generated-file-manifest.yaml`
- `component-coverage.yaml`
- `component-api-conformance.yaml`
- `manual-api-inventory.yaml`

These manifests are machine-readable artifacts produced by the report stage
from upstream metadata, discovered generated outputs, and handwritten policy
inputs.

The same report stage also produces human-readable diagnostic summaries written
to:

```text
report/
```

This separation ensures that:

- **generation** produces deterministic build artifacts
- **manifests** capture structured information about the generated system
- **reporting** evaluates and summarizes coverage and conformance

Both the `manifests/` and `report/` directories are fully regenerable and are not
bundled with the package itself.

---

# Summary

The `shiny.webawesome` architecture combines:

* automated wrapper generation
* a minimal Web Awesome runtime bundle
* automated Web Awesome dependency loading
* Shiny input bindings
* a reproducible build pipeline
* a mechanism for generating manifests and reports of the build

This design ensures that the R interface remains synchronized with Web Awesome while maintaining a small and maintainable package.
