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
* When upstream metadata maps an HTML attribute to a materially different
  component field/property name after normalization, generated wrapper
  documentation should remain attribute-first and explicitly document that
  distinction for users. Routine kebab-case versus camelCase conversions do
  not need extra explanation. When a same-name live property also exists,
  the generated documentation should make that stronger ambiguity explicit
  rather than implying the wrapper argument targets the live property.
* Wrapper-only components use `id` for the DOM `id` attribute.
* Components with generated Shiny input bindings use `input_id` as the
  user-facing Shiny identifier, and that value is also written to the
  rendered DOM `id` attribute.
* For components with generated Shiny input bindings, `input_id` is the
  first positional argument in the generated R wrapper signature.
* Generated roxygen for identity arguments must document this distinction
  explicitly so users can tell whether a wrapper argument is a generic DOM id
  or a Shiny input id that also becomes the DOM id.

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
- When a metadata gap affects support-model classification, prefer a narrow
  handwritten policy input over broad hard-coded generator exceptions.
- Policy overrides should adjust generator decisions, not patch generated files
  after the fact.

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
inst/www/wa/
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

The package uses the Web Awesome autoloader/runtime loader utilities rather
than the monolithic runtime entry.

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
3. The bootstrap script loads the browser-ready autoloader utility.
4. The bootstrap script starts the loader.
5. The loader registers Web Awesome components dynamically.

---

# Shiny Event Binding Scope

## Decision

Generated Shiny input bindings subscribe only to **state-commit,
input-value events** that fit Shiny's reactive input model by default, with a
small explicit exception path for action-style controls that require a
different support model.

## Rationale

Web Awesome exposes browser events for many purposes, including value
commit, interaction feedback, visibility changes, and other component-local
behavior.

Shiny input bindings, however, should represent changes to the component's
reactive input value rather than mirror every browser event emitted by the
component.

Restricting generated bindings to value-oriented events keeps the package's
reactive surface smaller, avoids unnecessary server chatter, and preserves a
clear separation between:

* browser-local interaction handling
* Shiny server-side reactive input updates

This is especially important for high-frequency or transient interaction
events such as hover telemetry, which are better handled in browser-side
JavaScript unless a specific feature explicitly opts into forwarding them.

At the same time, some components semantically mirror native interactive
controls whose expected Shiny behavior is **action-oriented** rather than
value-oriented. In rare cases, upstream metadata may omit the relevant native
or inherited event from the component event declarations even though the
component should still participate in Shiny as an action input.

These cases should not be forced through the value-input model. Instead, they
justify a narrow generator policy seam that can explicitly classify a
component as an **action binding** when the metadata alone is insufficient.

## Implementation Rules

* Binding classification should prefer events that mean "the component's
  current input value changed".
* Generated bindings should subscribe to one supported value/commit event and
  then read the component's current value for delivery to Shiny.
* Action-style bindings must be opt-in through a narrow handwritten policy
  layer; they must not be inferred casually from arbitrary browser events.
* Action-style bindings should use dedicated action semantics appropriate for
  Shiny event inputs, rather than pretending the component exposes a useful
  value payload.
* Upstream custom events must not be forwarded to Shiny automatically merely
  because they exist in component metadata.
* High-frequency or interaction-only events should remain browser-side by
  default.
* The exact supported event-name heuristics may evolve as component coverage
  broadens, but they should remain constrained to the value-oriented event
  model above unless an explicit action-binding policy entry says otherwise.

## Deferred Follow-up

The package may eventually offer an **opt-in client-side helper layer** that
makes it easier for app authors to attach focused JavaScript handlers to
component-specific Web Awesome events without routing those events through
Shiny's server input mechanism.

This is deferred. It is not part of the current generator or binding model.

---

# Component Method Exposure

## Decision

Upstream Web Awesome component methods are **not** part of the generated
package API at this stage.

## Rationale

Web Awesome components may expose imperative browser methods such as
`focus()`, `blur()`, `show()`, and `hide()`.

These methods are useful, but they are not the same thing as Shiny input
value changes and should not be folded into the input-binding model.

Keeping methods out of the current generated surface avoids prematurely
mixing three distinct concerns:

* reactive value synchronization with the Shiny server
* imperative server-to-browser commands
* client-side component-local behavior

## Implementation Rules

* Generated input bindings and update helpers should continue to focus on
  reactive value transport, not general imperative method calls.
* The metadata and schema may eventually track upstream methods for reporting
  or future generation, but methods are not currently exposed automatically
  in generated R wrappers, bindings, or update helpers.

## Deferred Follow-up

If method support is added later, it should stay explicitly separate from the
reactive input-value model and likely take two opt-in forms:

* a **server-side command layer** for imperative browser actions, for example
  helper functions that send a targeted message instructing one component
  instance to call a supported method such as `focus()` or `blur()`
* a **client-side helper layer** that makes it easier for app authors to call
  component methods from JavaScript without inventing ad hoc selectors and
  event wiring for each app

Any future method surface should be selective and capability-based rather than
blindly exposing every upstream method automatically. Common UI methods such
as `focus()` and `blur()` are much better candidates than complex
component-specific methods with richer argument contracts.

Likewise, if future support is added for writable live component properties
that are distinct from constructor-time HTML attributes, that support should
remain separate from the generated wrapper constructor surface. Live-property
control is better treated as part of a distinct server/client command or
update layer than as an overloaded constructor argument convention.

This is deferred. It is not part of the current generator or binding model.

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
