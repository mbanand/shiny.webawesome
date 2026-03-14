# Testing Strategy

This document describes the **testing architecture used in the `shiny.webawesome` project**.

Because the package combines:

* generated R wrappers
* Web Components
* JavaScript Shiny bindings
* browser runtime behavior

testing is performed using **two complementary layers**:

1. **Unit tests** for generated R wrappers
2. **Functional browser tests** for runtime behavior

These layers validate both the **static correctness of generated code** and the **dynamic behavior of components inside Shiny applications**.

---

# Testing Goals

The testing system is designed to verify:

* correctness of generated wrapper functions
* correct mapping between R arguments and HTML attributes
* correct dependency loading behavior
* correct Shiny input binding behavior
* correct propagation of events and values
* correct behavior of `update_wa_*()` functions

The test system also ensures that:

* the generator produces valid wrappers
* runtime assets load correctly
* component behavior remains stable across Web Awesome updates

---

# Layer 1: Unit Tests

Unit tests validate the **static behavior of R wrapper functions**.

These tests do not require a browser and run quickly.

Unit tests are implemented using:

```text
testthat
```

and are stored in:

```text
tests/testthat/
```

---

## What Unit Tests Verify

Unit tests typically verify:

* wrapper functions produce the correct HTML tag
* R arguments map to the correct HTML attributes
* kebab-case attributes convert correctly to snake_case arguments
* logical arguments produce correct boolean attributes
* enumeration arguments validate allowed values
* dependency helpers attach Web Awesome runtime assets

Example conceptual test:

```r
ui <- wa_button("Click", appearance = "filled") #>

expect_true(grepl("<wa-button", as.character(ui)))  #>
```

These tests ensure that wrapper generation remains correct even when generator logic changes. (Ignore the #> at the end of the lines in the examples above - these are there to fix syntax highlighting annoyances).

---

## Generated Wrapper Coverage

Because wrappers are generated automatically, the project aims to provide **basic unit test coverage for every component wrapper**.

Typical coverage includes:

* wrapper construction
* argument handling
* attribute conversion
* dependency behavior

The goal is to ensure that the generator produces valid R functions for all Web Awesome components.

---

# Layer 2: Functional Tests

Functional tests verify **runtime behavior inside a real browser environment**.

These tests validate:

* Web Component loading
* Shiny input binding behavior
* event propagation
* server-side update behavior

Functional tests are implemented using:

```text
shinytest2
```

---

## What Functional Tests Do

Functional tests perform tasks such as:

* launching a small Shiny application
* interacting with components through a browser
* verifying reactive values
* verifying events reach the server
* verifying `update_wa_*()` functions update component state

Example conceptual interaction:

```text 
launch app
click button
observe Shiny input change
```

These tests verify the full integration between:

* Web Awesome
* JavaScript bindings
* the Shiny reactive system

---

# Test Harness Applications

Functional tests use **small test harness applications** designed specifically for testing components.

These applications:

* render a small set of components
* display reactive values in the UI
* allow automated interaction via the test framework

Example conceptual structure:

```text 
app/
  ui.R
  server.R
```

The harness apps allow automated tests to:

* simulate user interaction
* observe server responses
* verify component state changes

---

# Update Function Testing

Special attention is given to testing generated update functions.

Example functions:

```text 
update_wa_select()
update_wa_input()
```

Tests verify that:

* server-side updates reach the browser
* component state changes correctly
* updated values propagate through Shiny bindings

These behaviors require browser-level tests and therefore are validated in the **functional testing layer**.

---

# CRAN Testing Policy

Browser-based tests require a working browser environment.

CRAN build environments may not provide this reliably.

Therefore the project follows this rule:

* **Unit tests run on CRAN**
* **Functional browser tests are skipped on CRAN**

This is implemented using:

```r 
testthat::skip_on_cran()
```

Functional tests still run during:

* local development
* continuous integration (CI)

---

# Continuous Integration

The project should run the **full test suite in CI environments**.

CI environments should include:

* R
* Node/npm (for Web Awesome fetch step if required)
* a Chromium-based browser for `shinytest2`

The CI pipeline should execute:

```text 
clean → fetch → prune → generate → test → report
```

This ensures that:

* the generator pipeline works
* wrappers regenerate correctly
* runtime behavior remains valid

---

# Testing the Generator

The generator itself is indirectly tested through the wrapper and functional tests.

Because wrapper code is generated from metadata, any generator error will typically result in:

* incorrect wrapper output
* incorrect binding behavior
* failing unit tests

Therefore the test system provides **automatic coverage for the generator pipeline**.

---

# Build/pipeline scripts testing

Handwritten build and generator scripts must be verified by:

* loading without syntax errors
* executing successfully
* producing expected artifacts
* supporting downstream validation and repeatable regeneration

---

# Testing Philosophy

The testing philosophy for `shiny.webawesome` is:

* **verify generated code rather than hand-writing exhaustive tests**
* **focus on representative runtime behaviors**
* **maintain lightweight but broad coverage**

This approach keeps the test suite manageable while still detecting generator regressions.

---

# Coverage and Conformance Verification

In addition to unit tests and functional tests, the project should verify
coverage and conformance against upstream Web Awesome metadata.

This includes three distinct checks:

1. **Generated file integrity**
    - expected generated files exist
    - stale generated files are removed
    - unexpected generated files are detected

2. **Upstream component coverage**
    - the set of upstream Web Awesome components is compared against the set of components implemented in the package
    - skipped or deferred components are tracked explicitly rather than being treated as silent omissions

3. **Component API conformance**
    - generated wrappers, update functions, and bindings are checked against upstream metadata for the intended set of supported attributes, properties, events, and slots

These checks should be deterministic and machine-verifiable where possible.

Coverage and conformance verification complements, but does not replace,
behavioral testing of the package.

---

# Package and user-facing documentation

Use `devtools::document()` to generate, verify and keep up-to-date package and user-facing documentation.

---

# Summary

The testing system combines two complementary layers.

Unit tests verify the correctness of generated wrapper functions.

Functional tests verify runtime behavior in a browser environment.

Together these tests ensure that:

* the generator produces valid code
* components behave correctly in Shiny applications
* updates and events propagate correctly

This layered approach provides confidence that the package remains stable as Web Awesome evolves.



