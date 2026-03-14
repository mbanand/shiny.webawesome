# shiny.webawesome — Architecture

This document describes the internal architecture of the shiny.webawesome package.

---

# Core Architecture

The package uses a **generator-driven architecture**.

Component wrappers, update functions, bindings, and documentation are generated automatically from Web Awesome metadata.

The authoritative metadata source is:

custom-elements.json

from the Web Awesome distribution.

---

# Generator Philosophy

The project is **generator-first**.

Generated code should never be edited manually.

If behavior cannot be expressed through generation logic, a **minimal manual override layer** is used.

Overrides must not modify generated files directly.

---

# Metadata Source

Web Awesome publishes metadata describing all components.

This metadata includes:

* component tag names
* attributes
* properties
* events
* slots

The metadata is stored locally in:

inst/extdata/webawesome/

and used by the generator.

---

# Repository Structure

shiny.webawesome/

R/
core/
generated/
generated_updates/

inst/
www/webawesome/
extdata/webawesome/
bindings/

tests/testthat/

tools/
docs/
vendor/
man/
vignettes/

---

# Directory Responsibilities

## R/core

Handwritten package logic.

---

## R/generated

Generated wrapper functions.

Examples:

wa_button.R
wa_input.R

---

## R/generated_updates

Generated update functions.

Examples:

update_wa_button.R
update_wa_input.R

---

## inst/www/webawesome

Pruned runtime bundle used by Shiny.

---

## inst/extdata/webawesome

Metadata used by the generator.

---

## inst/bindings

Generated Shiny JavaScript bindings.

---

## vendor

Cached upstream Web Awesome distribution.

---

# Generator Outputs

The generator produces:

R/generated/
wa_button.R
wa_input.R
...

R/generated_updates/
update_wa_button.R
...

inst/bindings/
wa-button.js
...

These files are automatically regenerated during the build pipeline.

---

# Runtime Model

At runtime:

1. R wrapper emits a Web Component HTML tag
2. Web Awesome dependency is attached
3. Web Awesome runtime loads component module
4. Custom element upgrades
5. Shiny bindings synchronize events and values

---

# Dependency Injection

Dependencies are attached automatically when components are used inside standard Shiny layouts such as:

fluidPage()
semanticPage()

The package also provides:

wa_page()

which constructs a page and attaches the dependency exactly once.
