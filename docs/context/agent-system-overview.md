# shiny.webawesome — Agent System Overview

This document summarizes how coding agents are expected to operate in the
`shiny.webawesome` repository.

The project is designed to support development with coding agents such as
Codex CLI while maintaining strong architectural constraints.

---

# Agent Guidance Layers

Agent guidance in this repository follows a layered model.

Layer 1 — Project Context  
High-level documentation describing the system architecture and development workflow.

Layer 2 — Agent Rules  
Rules in `AGENTS.md` that define repository constraints and invariants.

Layer 3 — Development Playbook  
`docs/workflow/agent-development-playbook.md` describes how agents and humans
collaborate to perform development tasks.

Layer 4 — Skills (optional)  
Small repeatable workflows used for common tasks such as regeneration,
verification, or dependency updates.

---

# Development Philosophy

Agents should treat the repository as a **generator-driven system**.

Most package code is produced automatically from upstream Web Awesome metadata.

Agents should modify:

- generator logic
- templates
- metadata parsing
- build pipeline scripts

rather than manually editing generated outputs.

---

# Deterministic Development

Agents should strive for deterministic and repeatable outputs.

This includes:

- stable ordering of generated files
- consistent code formatting
- deterministic regeneration
- reproducible build pipelines
