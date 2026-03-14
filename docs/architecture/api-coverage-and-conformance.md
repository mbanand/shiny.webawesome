# API Coverage and Conformance

This document defines how `shiny.webawesome` tracks implementation coverage
against the upstream Web Awesome API.

The project distinguishes between file generation integrity, upstream
component coverage, component API conformance, and handwritten package APIs.

---

# Overview

The package is generator-driven and derives much of its API from upstream
Web Awesome metadata.

To maintain correctness over time, the project tracks four related but
distinct concerns:

1. generated file integrity
2. upstream component coverage
3. per-component API conformance
4. handwritten package API inventory

These concerns should not be collapsed into a single mechanism.

---

# Generated File Integrity

Generated file integrity answers:

- which generated files should exist
- whether expected generated files are missing
- whether stale generated files remain
- whether unexpected generated files were emitted

This is tracked using a generated file manifest.

The generated file manifest is concerned with file-level correctness only.

It does not describe whether the package fully covers the upstream API.

---

# Upstream Component Coverage

Upstream component coverage answers:

- which Web Awesome components exist upstream
- which upstream components are implemented in `shiny.webawesome`
- which components are intentionally skipped
- which components remain pending
- why a component is skipped or deferred

This should be tracked in a deterministic coverage manifest or coverage table.

Coverage should be explicit rather than inferred from generated files alone.

---

# Component API Conformance

Component API conformance answers:

- whether a generated wrapper reflects the intended upstream API for a component
- whether supported attributes, properties, events, and slots are represented
- whether update functions and bindings are complete relative to the selected support model

Conformance should be checked against upstream metadata rather than maintained
only as handwritten notes.

Conformance checks may be partial during development, but they should be
deterministic and machine-verifiable.

---

# Handwritten Package API Inventory

The package may also provide handwritten APIs that do not correspond directly
to upstream Web Awesome components.

Examples may include:

- layout helpers
- page helpers
- utilities such as `wa_grid()`

These should be tracked separately from upstream coverage because they are
package-level design choices rather than mirrors of upstream components.

Handwritten package APIs should have their own inventory and documentation.

---

# Recommended Artifacts

The following artifacts are recommended:

- a generated file manifest for file-level integrity
- an upstream component coverage manifest for tracking implemented, skipped,
  and pending components
- machine-verifiable conformance checks for generated wrappers, updates,
  and bindings
- a handwritten API inventory for package-defined helpers and utilities

---

# Summary

The project should verify not only that files are generated correctly, but
also that the package remains complete and consistent relative to the
upstream Web Awesome API and its own handwritten package surface.


