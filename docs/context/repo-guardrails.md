# Repository Guardrails

This document summarizes structural guardrails that protect the repository
during development.

---

# Generated Files

The repository contains directories that hold generated code.

These files must **not be edited directly**.

Generated directories include:

- `R/generated/`
- `R/generated_updates/`
- `inst/bindings/`

Changes should be made in generator logic and then regenerated.

---

# Generated File Headers

Generated files should contain a header indicating that they are automatically
generated and must not be manually edited.

---

# Deterministic Ordering

Generators must produce deterministic outputs.

This includes:

- sorting component names before generation
- sorting attributes and metadata
- writing files in stable order

Deterministic ordering prevents unnecessary diffs and keeps regeneration stable.

---

# Generated File Manifest

The project may maintain a generated file manifest that lists the expected
generated outputs.

Verification scripts should ensure that:

- expected files exist
- stale generated files are removed
- unexpected files are detected

---

# Environment Isolation

Development with coding agents may occur inside isolated environments such as
virtual machines.

Agents should operate only within the repository workspace and should not
modify files outside the repository.


