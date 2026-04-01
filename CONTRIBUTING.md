# Contributing

Thank you for contributing to `shiny.webawesome`.

Repository paths mentioned below refer to paths in the source repository.

## Before you change code

- Read the authoritative project documentation under `projectdocs/`.
- Follow the generator-first architecture described in [AGENTS.md](AGENTS.md).
- Do not edit generated files directly.

Generated and derived surfaces include, in particular:

- generated component files under `R/`
- generated bindings under `inst/bindings/`
- generated manifests under `manifests/`
- generated reports under `reports/`

If generated output is wrong, fix the generator, templates, metadata parsing,
or build logic, then regenerate.

## Development workflow

The core package workflow is:

`clean -> fetch -> prune -> generate -> test -> report`

When generator or build logic changes, regenerate the affected outputs and run
the relevant validation steps.

## Style and validation

Handwritten R code should follow the Tidyverse style guide:
<https://style.tidyverse.org>

When applicable:

- format with `styler`
- lint with `lintr`
- run relevant tests before considering the work complete

Formatting and linting are separate checks in this repository. Do not treat a
successful style pass as a substitute for linting.

## Documentation

Update `projectdocs/` when changes affect:

- architecture
- workflow
- testing approach
- build orchestration
- other documented project rules

User-facing package documentation should also be kept in sync with public API
changes.

## Pull requests and issues

- Keep changes scoped and reviewable.
- Explain generator or workflow changes clearly.
- Call out any intentional follow-up work or deferred items.
- Link relevant issues when applicable.

## Conduct

By participating in this project, you agree to follow the standards in
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
