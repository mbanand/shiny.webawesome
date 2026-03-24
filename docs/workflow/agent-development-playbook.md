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

Internal handwritten helpers should usually have a single concise comment line
immediately above the function definition. Prefer comments that explain
purpose or scope rather than restating the function name, and omit them for
trivial helpers whose purpose is already obvious.

Generated exported functions should have generated roxygen docs if they are part of the package API.

Handwritten build-tool entry points under `tools/` and `tools/runners/` should
also use roxygen2-style documentation. Tool documentation is generated
separately from package documentation; use `document_tools()` to regenerate the
artifacts written to `tools/man/`. Tool roxygen blocks should strongly prefer
ASCII-only text. (The current `document`-based workflow emits a benign warning
about missing `Encoding: UTF-8` in its temporary fake package; with ASCII-only
tool docs, this does not affect the generated output.)

Handwritten tooling code is organized by role:

- `tools/` for top-level tool entry points and reusable tool scripts
- `tools/runners/` for thin CLI runners around stage functions
- `tools/testthat/stages/` for reusable stage implementation tests
- `tools/testthat/runners/` for thin runner tests
- `tools/testthat/tools/` for top-level tool script tests
- `tools/man/` for generated tool documentation artifacts; this directory is
  generated and should not be kept as source in git

CLI entry-point scripts should include a shebang, support direct execution from
the repository root (for example `./tools/test_tools.R`), and be tracked in git
with executable mode.
Unless a script explicitly documents otherwise, CLI tooling should be invoked
from the repository root.
Direct execution is preferred for CLI entry points, but `Rscript path/to/script.R`
should remain a supported invocation style as well.

Top-level orchestration should remain explicit:

- `test_tools.R` runs the tool test suite
- `document_tools.R` regenerates tool documentation
- `build_tools.R` orchestrates the top-level tool workflow
- `build_package.R` runs `build_tools.R` first, then executes the currently
  available package-build step scripts

Do not wire package-level `devtools::document()`, `devtools::test()`, or
`devtools::check()` into `build_package.R` before the generate stage exists and
produces a real package surface to validate.

Once generation exists, these package-level actions should be added as
separate top-level `build_package.R` steps, not collapsed into one combined
"generate package" action. They should also support explicit skip flags, and
`devtools::check()` should be treated as the heaviest optional local gate.

---

# Running Validation

## Handwritten code validation

Handwritten R code should follow the Tidyverse style guide, available at https://style.tidyverse.org. 

Use `{styler}` for formatting and `{lintr}` for style checks where applicable.

For handwritten R files, including build-stage scripts under `tools/` and CLI
runners under `tools/runners/`, prefer a small external surface per file.
Typically a file should expose one main entry point, or at most a small number
of intentionally external functions. Internal helpers should typically start
with a leading period, for example `.parse_metadata()`. These helpers should
usually have a single concise comment immediately above the function
definition, unless the helper is trivial and already self-explanatory.

Agents should verify handwritten scripts that they can load cleanly, then run them, check output, and verify that they produce the expected artifacts. 

For handwritten code, do not defer all formatting and lint cleanup until the
end of a long task. Run `{styler}` and `{lintr}` periodically after meaningful
batches of edits so the diff stays reviewable and style drift is corrected
early. For standalone tool scripts that source helpers dynamically at runtime,
apply targeted lint suppressions only where static analysis would otherwise
produce false positives.

---

## Code style formatting of generated files

Generated R files should be formatted using the tidyverse style guide.

After generating or modifying code under generated directories such as:

- top-level `R/`

agents should run on the relevant directory, such as:

```r
styler::style_dir("R")
```

This ensures generated code follows consistent formatting and prevents
unnecessary diffs caused by whitespace or indentation differences.

Styling should be applied only after generation is complete, not during
template construction.

This is an explicit required step after every generate run that writes package
files under top-level `R/`. Do not treat post-generate styling as optional,
because template-correct code can still drift from tidyverse formatting after
generator changes or debug passes.

After styling generated files, run a relevant lint pass as a separate
required validation step so formatting fixes and lint findings are not
conflated. Do not treat the post-generate workflow as complete after
`{styler}` alone; generated R output should go through both `{styler}` and
`{lintr}`.

---

## Generated code validation

After making changes, agents should run the relevant validation steps.

This repository follows the standard validation workflow for R packages.

Typical validation flow is:

- generating components
- styling generated code
- running a separate relevant lint pass
- running documentation generation
- running unit tests
- running functional tests
- running a full package check

Typical commands:

```r
styler::style_dir("R")
lintr::lint("R")
devtools::document()
devtools::test()
devtools::check()
```

`devtools::check()` runs a full package validation similar to CRAN checks.

This package-level validation flow applies once generated package code exists.
Before the generate stage is implemented, `build_package.R` should stop at the
currently implemented package stage scripts instead of trying to run
package-level `devtools::*` steps prematurely.

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
* A dedicated `Deferred items` section listing any intentionally deferred work,
  open architectural questions, or consciously postponed follow-ups that
  remain active after the session
* List of docs updated, if any
* Short summary of any discussions, and decisions made
* Notes on any pitfalls/reminders, and pointers for future

Deferred items should not be buried only in discussion notes or next-step
lists. They should be kept in their own section so they are easy to review at
the start of the next session.

When writing a new journal, explicitly review the prior journal's deferred
items and carry forward every item that is still active.

Only remove a deferred item when one of the following is true:

* it was completed in the current session
* it was explicitly rejected or struck off
* it was replaced by a more precise deferred item that supersedes it

If a deferred item is carried forward in revised form, the new wording should
make that relationship clear enough that continuity is preserved.

---

# Summary

When working on this repository, agents should:

- follow the generator-driven architecture
- modify generator logic rather than generated files
- follow the clean → fetch → prune → generate → test → report workflow
- run validation checks including `devtools::test()` and `devtools::check()`
  once generated package surface exists
- update documentation when architecture changes occur
- prefer small, well-scoped tasks
- make safe progress when possible but do not invent architecture
