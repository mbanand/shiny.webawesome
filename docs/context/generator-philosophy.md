# Generator Philosophy

The `shiny.webawesome` package follows a generator-driven architecture.

Much of the package API is derived automatically from upstream Web Awesome
metadata.

---

# Generator Responsibilities

The generator is responsible for producing:

- component wrapper functions
- update functions
- JavaScript bindings
- documentation where appropriate

Generated files are written to dedicated directories.

---

# Regeneration Workflow

Changes to generator logic should be followed by regeneration.

Typical steps:

clean → fetch → prune → generate → test

Agents should regenerate outputs rather than manually editing generated files.

---

# Coverage and Conformance

The project aims to track:

- upstream component coverage
- per-component API conformance
- generated file integrity

Coverage and conformance checks help ensure the package remains aligned with
the upstream Web Awesome API.

---

# Manual APIs

The package may include handwritten helper functions such as layout utilities.

These APIs are not derived directly from upstream Web Awesome metadata and
should be tracked separately from component coverage.
