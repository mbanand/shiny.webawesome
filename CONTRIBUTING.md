# Contributing

Thank you for contributing to `shiny.webawesome`.

Repository paths mentioned below refer to paths in the source repository.

## Before you change code

- Read the authoritative project documentation under `projectdocs/`.
- Do not edit generated files directly.

Generated and derived surfaces include, in particular:

- generated component files under `R/`
- generated bindings under `inst/bindings/`
- generated manifests under `manifests/`
- generated reports under `reports/`

If generated output is wrong, fix the generator, templates, metadata parsing,
or build logic, then regenerate.

## Development workflow

The full documented pipeline is:

`clean -> fetch -> prune -> generate -> test -> report -> finalize -> publish`

In ordinary development, work often stops before the release-oriented stages.
The recurring local package-build flow usually runs through `report`, with
`finalize` used for late-stage release preparation and `publish` kept as a
separate explicit maintainer decision because it changes external release
state.

When generator or build logic changes, regenerate the affected outputs and run
the relevant validation steps. Do not edit generated package files, manifests,
reports, or bundled runtime outputs directly.

## Style and validation

Handwritten R code should follow the Tidyverse style guide:
<https://style.tidyverse.org>

When applicable:

- format with `styler`
- lint with `lintr`
- run relevant tests before considering the work complete

Formatting and linting are separate checks in this repository. Do not treat a
successful style pass as a substitute for linting.

For late-stage finalize work, the repository also expects the developer
environment to support:

- handwritten JavaScript linting via ESLint
- the package/site validation tooling used by `finalize`

The current official ESLint bootstrap command is
`npm init @eslint/config@latest`.

## Documentation

Update `projectdocs/` when changes affect:

- architecture
- workflow
- testing approach
- build orchestration
- other documented project rules

User-facing package documentation should also be kept in sync with public API
changes.

Contributor-facing docs should also stay synchronized with the actual stage
contracts. If you change the workflow around `report`, `finalize`, or
`publish`, update:

- `projectdocs/`
- maintainer-facing long-form docs such as `vignettes/articles/build-tools.Rmd`
- any contributor guidance that describes the workflow directly

## Coding agents

If you use a coding agent in this repository, start by having it read
[AGENTS.md](AGENTS.md) for behavioral control and then the project
documentation under `projectdocs/`, beginning with
`projectdocs/README.md`.

Those documents are written for both human contributors and coding agents.
They provide the repository context that an agent needs, including
architecture, generator-first workflow rules, generated-file boundaries,
testing strategy, and coverage/conformance expectations.

A good initial prompt is:

`Follow AGENTS.md. Read project documentation under projectdocs/ starting with projectdocs/README.md.`

Review all agent-generated code, documentation, issues, and pull requests
before submitting them.

## Pull requests and issues

- Keep changes scoped and reviewable.
- Explain generator or workflow changes clearly.
- Call out any intentional follow-up work or deferred items.
- Link relevant issues when applicable.

## Conduct

By participating in this project, you agree to follow the standards in
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
