# shiny.webawesome Documentation

This directory contains the **authoritative project documentation** for the `shiny.webawesome` package.

These documents describe the architecture, design decisions, development workflow, testing strategy, and conformance tracking and reporting mechanisms used in this project. They are intended for both human developers and coding agents working in the repository.

All implementation work in this repository should follow the rules and design principles documented in these documents.

---

# About shiny.webawesome

`shiny.webawesome` provides a complete **R / Shiny interface to the Web Awesome component library**.

The package exposes Web Awesome components as native R functions that can be used inside Shiny applications. These wrappers are generated automatically from Web Awesome component metadata and are designed to closely mirror the upstream Web Awesome API.

Key goals of the project include:

* Provide a comprehensive Shiny interface to Web Awesome components
* Mirror the upstream Web Awesome API as closely as possible
* Automatically generate component wrappers from Web Awesome metadata
* Bundle a minimal runtime subset of Web Awesome compatible with CRAN size limits
* Maintain a reproducible build pipeline for updating Web Awesome versions

---

# Documentation Structure

This documentation is organized into four primary sections.

## Architecture

The architecture documents explain the internal design of the package and how
its components interact.

* `architecture/overview.md`
  High-level explanation of the system architecture.

* `architecture/decisions.md`
  Record of important architectural decisions made during development.

* `architecture/package-structure.md`
  Description of the repository and R package directory structure.

* `architecture/generated-files.md`
  Guardrails and rules for working with generated files.

* `architecture/api-coverage-and-conformance.md`
  Describes how the project tracks implementation coverage against the
  upstream Web Awesome API.

## Development

Development documentation describes internal infrastructure used during the
build process.

* `development/manifests.md`
  Overview of the manifest system used to track generated files, component
  coverage, API conformance, and manual package APIs.

* `development/component-coverage.md`
  Detailed description of the component coverage manifest and the policy layer
  used to track upstream component support.

## Workflow

Workflow documentation describes the development and build process.

* `workflow/build-pipeline.md`
  Defines the pipeline used to fetch Web Awesome, prune runtime assets,
  generate wrappers, run tests, and report coverage/conformance.

* `workflow/agent-development-playbook.md`
  Provides detailed guidance on how development tasks should be executed when
  working with coding agents.

## Testing

Testing documentation describes the testing approach used in the repository.

* `testing/testing-strategy.md`
  Describes the two-layer testing strategy using `testthat` and `shinytest2`.

---

# Relationship to `AGENTS.md`

The repository will also contain an `AGENTS.md` file used by coding agents.

`AGENTS.md` provides instructions about how agents should operate within the repository, while the documents in this directory describe the **system architecture and development process**.

Agents should consult this documentation for:

* project structure
* design constraints
* development workflow
* testing requirements
* conformance tracking and reporting requirements

---

# Development Lifecycle Overview

The full development and release pipeline for this project is:

clean → fetch → prune → generate → test → report → finalize → publish

Where:

* **clean** removes generated files and bundled runtime assets
* **fetch** downloads a pinned version of Web Awesome
* **prune** creates a minimal runtime bundle for the package
* **generate** builds R wrappers and bindings from component metadata
* **test** runs unit tests and browser-based functional tests
* **report** generates manifests and reports
* **finalize** performs late-stage release-preparation validation, rebuilds
  declared derived artifacts such as package docs, the pkgdown site, and the
  release tarball, and writes a machine-readable release handoff record
* **publish** is a separate explicit maintainer-invoked release stage that
  verifies the finalize handoff, may perform selected external release
  actions such as creating release state in git and deploying the already-built
  website, and does not cover CRAN submission

Details of this workflow are documented in:

`workflow/build-pipeline.md`

---

# Audience

This documentation is written for:

* maintainers of `shiny.webawesome`
* contributors to the repository
* coding agents operating within the project

It assumes familiarity with:

* R package development
* Shiny applications
* modern JavaScript component libraries

