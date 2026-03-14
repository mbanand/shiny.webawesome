# shiny.webawesome — Project Overview

This document provides a high-level overview of the **shiny.webawesome** project.

---

# Project Goal

`shiny.webawesome` is an R package that provides a **Shiny interface to the Web Awesome component library**.

The package exposes Web Awesome **Web Components** as R functions that can be used directly in Shiny applications.

Example mapping:

Web Awesome HTML

<wa-button appearance="filled">Click</wa-button>

Shiny wrapper

wa_button("Click", appearance = "filled")

The R API mirrors the Web Awesome API closely while following standard R conventions such as **snake_case argument names**.

---

# Key Design Principles

## Generator-first architecture

Most code in the package is **generated automatically** from Web Awesome metadata.

Generated code includes:

- component wrapper functions
- update functions
- Shiny bindings
- documentation

Generated files should **never be edited manually**.

---

## Metadata-driven generation

The authoritative source of component metadata is:

custom-elements.json

from the Web Awesome distribution.

All component wrappers are generated from this metadata.

---

## Minimal manual layer

Handwritten code exists only where generation cannot reasonably express the required behavior.

Manual code lives primarily in:

R/core/

---

## CRAN compatibility

The package must remain compatible with CRAN constraints, including:

- package size limits
- test requirements
- dependency restrictions

The Web Awesome runtime bundle is therefore **pruned during the build pipeline**.

---

# Example Usage

Typical usage inside a Shiny app:

```r
library(shiny)
library(shiny.webawesome)

ui <- fluidPage(
  wa_button("Click me", appearance = "filled")
)

server <- function(input, output, session) {}

shinyApp(ui, server)
````

---

# Runtime Behavior

At runtime the following occurs:

1. The R wrapper emits the Web Component HTML tag.
2. The Web Awesome runtime dependency is attached.
3. The component module is dynamically loaded.
4. The custom element upgrades in the browser.
5. Shiny bindings connect component values and events.

---

# Current Project State

The project has completed its **initial architecture and documentation phase**.

The following documentation exists:

docs/README.md
docs/architecture/overview.md
docs/architecture/decisions.md
docs/architecture/package-structure.md
docs/workflow/build-pipeline.md
docs/testing/testing-strategy.md

A repository-level `AGENTS.md` file defines guidance for coding agents.

---

# Next Development Phase

The next phase is **implementation using a coding agent (Codex CLI)**.

Initial development tasks include:

1. Creating the repository directory structure

2. Implementing build tools

   * clean_webawesome.R
   * fetch_webawesome.R
   * prune_webawesome.R

3. Implementing the component generator

4. Generating initial wrappers and bindings

5. Building the test harness
