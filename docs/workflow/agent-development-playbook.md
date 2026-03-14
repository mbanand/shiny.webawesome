# Agent Development Playbook

This document describes how development tasks should be executed when working
with coding agents in the `shiny.webawesome` repository.

The goal is to ensure that agents produce reliable, consistent changes that
respect the generator-driven architecture of the project.

Agents should follow this playbook in addition to the rules defined in
`AGENTS.md`.

---

# Core Principle

Development in this repository is generator-driven.

Agents should prefer modifying:

- generator logic
- metadata parsing
- templates
- build pipeline scripts

rather than modifying generated outputs.

Generated files should never be edited directly.

---

# Task Size Guidelines

Agent tasks should be small and well-scoped.

Prefer tasks that involve:

- implementing one script
- modifying one subsystem
- adding one feature
- fixing one bug
- improving one generator behavior

Tasks should be issued in small, focused prompts rather than large, mixed requests..

Large tasks should be broken into sequential steps.

Example:

Bad task:

"Implement the full generator and runtime system."

Good sequence:

1. Implement metadata parsing.
2. Implement generator templates.
3. Implement wrapper generation.
4. Implement update function generation.
5. Generate initial components.

---

# Typical Development Cycle

Most development follows this workflow:

1. Modify generator logic or scripts.
2. Regenerate outputs.
3. Run validation checks.
4. Run tests.
5. Inspect generated code if necessary.
6. Generate reports.

The standard build pipeline is:

clean → fetch → prune → generate → test → report

Agents should use the scripts in `tools/` to run these steps.

---

# Regeneration Rules

When generator logic changes, agents should regenerate the affected outputs.

Typical regeneration steps:

```r
clean_webawesome()
generate_components()
```

Regeneration ensures that generated files reflect the current generator logic.

Generated files should not be manually edited.

---

# Updating Web Awesome Versions

When upgrading Web Awesome:

1. Fetch the new upstream version.
2. Rebuild the pruned runtime bundle.
3. Regenerate components.
4. Run the full validation suite.
5. Generate documentation.
6. Generate reports.

Typical commands:

```r
fetch_webawesome()
prune_webawesome()
generate_components()
devtools::test()
devtools::check()
devtools::document()
```

---

# Debugging Generator Issues

If the generator produces incorrect code:

1. Inspect the Web Awesome metadata.
2. Inspect generator templates and parsing logic.
3. Adjust the generator implementation.
4. Regenerate outputs.
5. Rerun validation and tests.

Agents should avoid patching generated files to fix generator bugs.

Generator issues should be fixed at the source.

---

# Package and code documentation

Public/user-facing R functions must have roxygen2 documentation.

Internal handwritten functions should have either roxygen2-style comments or clear inline comments as appropriate.

Generated exported functions should have generated roxygen docs if they are part of the package API.

---

# Running Validation

## Handwritten code validation

Handwritten R code should follow the Tidyverse style guide, available at https://style.tidyverse.org. 

Use `{styler}` for formatting and `{lintr}` for style checks where applicable.

Agents should verify handwritten scripts that they can load cleanly, then run them, check output, and verify that they produce the expected artifacts. 

---

## Code style formatting of generated files

Generated R files should be formatted using the tidyverse style guide.

After generating or modifying code under generated directories such as:

- R/generated/
- R/generated_updates/

agents should run on the relevant directory, such as:

```r
styler::style_dir("R/generated")
styler::style_dir("R/generated_updates")
```

This ensures generated code follows consistent formatting and prevents
unnecessary diffs caused by whitespace or indentation differences.

Styling should be applied only after generation is complete, not during
template construction.

---

## Generated code validation

After making changes, agents should run the relevant validation steps.

This repository follows the standard validation workflow for R packages.

Typical validation flow is:

- generating components
- styling generated code
- running documentation generation
- running unit tests
- running functional tests
- running a full package check

Typical commands:

```r
styler::style_dir("R/generated")
styler::style_dir("R/generated_updates")
devtools::document()
devtools::test()
devtools::check()
```

`devtools::check()` runs a full package validation similar to CRAN checks.

Agents should ensure that:

- no new warnings are introduced
- no new errors occur
- tests pass successfully
- documentation is generated successfully

Functional tests using `shinytest2` may launch browsers during development
but are skipped on CRAN.

---

# Coverage and Conformance Workflow

When generator logic or upstream metadata changes, agents should verify not
only that generation succeeds, but also that package coverage and API
conformance remain correct.

This includes checking:

- generated file integrity
- upstream component coverage
- per-component API conformance
- any affected handwritten package APIs

Agents should not assume that successful generation alone proves correctness.

When relevant, agents should:

1. regenerate outputs
2. verify the generated file manifest
3. review upstream component coverage status
4. run applicable conformance checks against upstream metadata
5. report any newly missing, extra, skipped, or partially implemented APIs

For handwritten helpers and utilities, agents should verify that they are
tracked separately from upstream component coverage and documented as part of
the package API.

---

# Inspecting Generated Code

Agents may inspect generated files to verify correctness.

However, generated files should not be manually edited.

If changes are required, the generator logic should be updated and the files
should be regenerated.

---

# When to Update Documentation

Documentation should be updated when changes affect:

- architecture
- repository structure
- build pipeline
- testing strategy
- generator behavior

Documentation updates should precede implementation when architecture changes
are required.

---

# Handling Uncertainty

If part of a task is unclear, agents should still make as much safe progress as
possible within the existing documented architecture.

Agents should not invent new architecture, silently change repository
constraints, or guess about behavior that is not documented.

When uncertainty arises, agents should:

1. Continue with the parts that are clear and well-scoped.
2. Follow existing documentation and repository patterns.
3. Surface the specific uncertainty clearly.
4. Propose one or more constrained options when helpful.
5. Ask for clarification only when the ambiguity blocks safe implementation.

Agents should prefer partial, correct progress over speculative changes.

---

# Keeping a journal

At the end of each session, when directed, a journal should be written under 
`journals/` to aid in workflow continuity. This directory will be ignored for
git repo and R package build purposes. It is a top-level repository directory
used only for workflow continuity.

The journal file should be a Markdown file, appropriately named with date and time.

It should contain:

* Date and time of journal 
* Bullet list of tasks completed, correctly interspersed with commits and branch changes
* Bullet list of three proposed next steps
* List of docs updated, if any
* Short summary of any discussions, and decisions made
* Notes on any pitfalls/reminders, and pointers for future

---

# Summary

When working on this repository, agents should:

- follow the generator-driven architecture
- modify generator logic rather than generated files
- follow the clean → fetch → prune → generate → test → report workflow
- run validation checks including `devtools::test()` and `devtools::check()`
- update documentation when architecture changes occur
- prefer small, well-scoped tasks
- make safe progress when possible but do not invent architecture

