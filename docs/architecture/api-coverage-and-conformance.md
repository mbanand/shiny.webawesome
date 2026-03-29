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

## Relationship to Testing

Component API conformance is **not** the same as the package's unit tests or
functional tests.

Tests answer questions such as:

- does a representative wrapper render the expected HTML structure
- does a representative component behave correctly in the browser
- does a representative Shiny input or update helper produce the intended
  reactive behavior

Conformance reporting answers a different question:

- does the generated package surface remain structurally aligned with the
  current generator contract across the full component set

This distinction matters because the two systems operate at different levels.

Tests are primarily **behavioral**:

- they verify user-visible behavior
- they exercise representative examples and harness applications
- they confirm that selected wrappers, bindings, and updates work in practice

Conformance reporting is primarily **structural**:

- it checks deterministic emitted package artifacts
- it runs across all generated components rather than only sampled cases
- it verifies that generated wrappers, updates, and bindings still match the
  generator-derived expectations for the current support model

As a result, conformance checks are intended to catch forms of silent drift
that behavioral tests may not cover exhaustively. Examples include:

- a generated wrapper whose argument ordering no longer matches generator rules
- a generated binding file whose selector, registration name, or subscribed
  event set drifts from the current binding classification
- a generated update helper whose surface no longer matches the message fields
  implied by the generator

Conformance reporting therefore **complements** tests rather than replacing
them. It should stay focused on deterministic generated-surface integrity and
should not try to become a second behavioral test suite inside the report
stage.

The current implemented conformance layer is intentionally artifact-first:

- wrapper function presence
- wrapper export presence
- expected binding file presence for bound components
- expected update-function presence and export status for update-capable components

It now also verifies several deterministic generated-surface details directly
against the current generator rules:

- wrapper argument surface and ordering
- wrapper normalized attribute payloads
- wrapper boolean attribute metadata (`boolean_names` and
  `boolean_arg_names`)
- wrapper slot-emission helper calls
- wrapper warning-hook emission where generator policy requires it
- update-helper argument surface and ordering
- binding selector registration
- binding registration name
- subscribed binding event set
- binding `getValue()` emission
- binding `getType()` emission
- binding subscribe-callback emission
- binding `receiveMessage()` emission
- mode-specific binding requirements such as action typing,
  semantic `receiveMessage()` behavior, and action-with-payload side-channel
  publication

This gives the project a deterministic baseline report stage now, while
leaving room for later passes to deepen per-component argument, property, and
event-level conformance checks.

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

The following artifacts are now part of the report stage:

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
