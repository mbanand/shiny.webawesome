# shiny.webawesome — Development Workflow

This document describes how development is performed on the shiny.webawesome repository.

---

# Build Pipeline

Development follows a deterministic pipeline:

clean → fetch → prune → generate → test

---

# Pipeline Steps

## clean

Removes generated artifacts and pruned runtime bundles.

---

## fetch

Downloads a pinned Web Awesome version from npm.

The downloaded distribution is stored in:

vendor/

---

## prune

Builds a minimal runtime bundle suitable for CRAN size limits.

The result is stored in:

inst/www/webawesome/

---

## generate

Parses Web Awesome metadata and generates:

* R wrapper functions
* update functions
* Shiny bindings
* documentation

---

## test

Runs unit tests and browser-based functional tests.

---

# Typical Development Cycle

During development the following steps are frequently run:

1. clean_webawesome.R
2. fetch_webawesome.R
3. prune_webawesome.R
4. generate_components.R
5. devtools::test()

---

# Testing Strategy

Two complementary testing layers are used.

---

## Unit Tests

Implemented using:

testthat

These verify:

* wrapper generation
* argument handling
* HTML output

---

## Functional Tests

Implemented using:

shinytest2

These tests launch small Shiny apps and verify:

* component behavior
* event propagation
* update functions

Browser tests run in development and CI but are **skipped on CRAN**.

---

# Key Constraints

The following constraints must always be respected:

* Generated files must never be edited manually
* Generator logic lives in `tools/`
* Runtime bundle must remain within CRAN size limits
* Browser tests must be skipped on CRAN
* R wrapper arguments mirror Web Awesome attributes using snake_case

---

# Coding-Agent Rules

Coding agents working on this repository should:

* treat the project as generator-driven
* avoid editing generated files directly
* modify generator logic instead
* follow the build pipeline
* run tests after changes
