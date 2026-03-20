# Repository and Package Structure

This document defines the **directory structure of the `shiny.webawesome` repository and R package**.

The structure separates:

* runtime assets
* generated code
* manual code
* build tools
* documentation
* tests
* manifests & reports

This separation allows the package to maintain a clear boundary between **generated artifacts and handwritten code**, while keeping the development workflow reproducible.

---

# Repository Overview

The repository is organized into several major sections.

```text
shiny.webawesome/
  R/
  inst/
  tests/
  tools/
  docs/
  journals/
  man/
  vignettes/
  vendor/
  dev/
  manifests/
  report/
  scratch/
  scripts/
```

Each section has a specific purpose.

---

# R Source Code for the Package

The `R/` directory contains all R source code included in the package.

Both handwritten and generated package source files live directly under `R/`.

```text
R/
  wa_dependency.R
  wa_page.R
  wa_card.R
  wa_select.R
  package.R
```

---

## Handwritten R Code

```text
R/
```

Handwritten files under `R/` implement core package functionality.

Examples include:

* dependency helpers
* page constructors
* slot helpers
* internal utilities

Typical files:

```text
wa_dependency.R
wa_page.R
wa_utils.R
```

These files are **maintained manually** and should not be overwritten by generators.

---

## Generated Component Wrappers

```text
R/
```

Top-level `R/` also contains **automatically generated component wrapper functions**.

Each Web Awesome component has a corresponding wrapper.

Examples:

```text
wa_button.R
wa_select.R
wa_input.R
wa_dialog.R
```

These files are produced by the component generator.

Generated files **should not be edited manually**.

They are regenerated whenever Web Awesome metadata changes.

---

## Generated Update Functions

Generated `update_wa_*()` functions for interactive components also live under
top-level `R/`, typically colocated with the corresponding wrapper when that
keeps a component API together.

Examples:

```text
wa_select.R
wa_input.R
wa_checkbox.R
```

These functions allow Shiny servers to update component state in the browser.

These files are also **generated automatically**.

---

## Manual Package Helpers

Not all package APIs correspond directly to upstream Web Awesome components.

The package may include handwritten helpers such as layout functions, page
constructors, or convenience utilities. These should be treated as part of the
package's manual API surface and tracked separately from upstream coverage.

Examples may include:

- `wa_page()`
- `wa_grid()`
- future layout or utility helpers

---

# Manual Override Layer

Although the package is generator-driven, it provides a **manual override layer** for edge cases.

Manual overrides allow developers to adjust behavior when a component cannot be handled entirely by the generator.

Overrides should not be implemented by editing generated files.

Instead, overrides must be implemented in dedicated locations that coexist with generated code.

Typical approaches include:

* defining helper functions in handwritten top-level `R/` files
* customizing generator templates
* adding special-case logic in generator scripts

The override layer should remain **small and explicit**.

Generated code remains the primary implementation mechanism.

---

# Runtime Assets

Web Awesome runtime files are bundled with the package.

They are stored in:

```text
inst/www/webawesome/
```

Example structure:

```text
inst/www/webawesome/
  webawesome.loader.js
  wa-bootstrap.js
  webawesome-init.js

  components/
  chunks/
  styles/
  utilities/
  translations/
  events/
```

These files are copied and pruned from the upstream Web Awesome distribution during the build process.

The `inst/www` directory is served automatically by Shiny when the package is loaded.

---

# Web Awesome Component Metadata

The Web Awesome component metadata file is stored in:

```text
inst/extdata/webawesome/
```

Example:

```text
inst/extdata/webawesome/
  custom-elements.json
  VERSION
```

This metadata is used by the code generator.

It is **not served to browsers** and is only used during code generation.
It is kept in the repository as build input and excluded from the built
package via `.Rbuildignore`.

---

# JavaScript Shiny Bindings

Generated JavaScript bindings are stored in:

```text
inst/bindings/
```

Example:

```text
inst/bindings/
  wa_select.js
  wa_input.js
  wa_checkbox.js
```

These bindings connect Web Awesome components to the Shiny reactive system.

---

# Tests

Automated tests are stored in:

```text
tests/testthat/
```

These include:

* unit tests for component wrappers
* tests for dependency behavior
* functional tests using `shinytest2`

Browser-based functional tests are skipped when running on CRAN.

---

# Build Tools

Development tools used to build the package are stored in:

```text
tools/
```

Example structure:

```text
tools/
  clean_webawesome.R
  fetch_webawesome.R
  prune_webawesome.R
  generate_components.R
```

Responsibilities of examples:

* `clean_webawesome.R` removes generated artifacts, copied metadata, and
  pruned runtime assets.
* `fetch_webawesome.R` downloads a pinned Web Awesome release.
* `prune_webawesome.R` creates the minimal runtime bundle, copies generation
  metadata into `inst/extdata/webawesome/`, and writes versioned prune reports.
* `generate_components.R` generates wrappers and bindings.

The clean tool supports two levels of cleanup:

* **clean** — removes generated files and pruned runtime assets
* **distclean** — also removes the fetched upstream Web Awesome cache stored under `vendor/`

Tools listed above are examples and not intended to be exhaustive. Other tools may be implemented as needed, for example: build manifest generation and reporting.

These scripts are used during development but are **not part of the runtime package**.

---

# Project Documentation

Project and developer documentation is stored in:

```text
docs/
```

Example structure:

```text
docs/
  architecture/
  workflow/
  testing/
```

These documents describe the system architecture, build pipeline, and testing strategy.

They are intended for:

* maintainers
* contributors
* coding agents

This documentation is **separate from the installed R package help system**.

---

# Local Working Directories

Some top-level directories exist to support development workflow but are not
part of the package itself.

### `journals/`

Session journals used for workflow continuity between development sessions.

This directory is intended to be ignored for both git and R package build
purposes.

### `scratch/`

Local scratch space for notes, experiments, and temporary working materials.

This directory is for repository-local development convenience and is not part
of the package build.

### `scripts/`

Convenience scripts used during local development.

These scripts are not package runtime assets and are not part of the package
build.

---

# Package Documentation

User-facing R package documentation is generated into:

```text
man/
```

These files are produced from **Roxygen comments** in both handwritten and generated R source files.

They provide the standard installed package help pages used by commands such as:

```r
?wa_button
?wa_select
```

The `man/` directory should be treated as **generated documentation**.

Longer-form user guides may also be stored in:

```text
vignettes/
```

if the package includes vignettes.

---

# Vendor Directory

The raw upstream Web Awesome distribution is stored in:

```text
vendor/webawesome/
```

Example:

```text
vendor/webawesome/
  3.x/
    dist/
```

This directory contains the **unmodified upstream distribution** downloaded from npm.

It is used as the source for pruning runtime assets.

The vendor directory is excluded from the built R package using:

```text
.Rbuildignore
```

---

# Package Build Files

Files that guide the package development and build are stored in `dev/`. These are not documentation files; rather they are machine-readable files that direct the package build or enforce policy. 

A current example is a policy file that drives manifest and report generation (see details in `docs/development/component-coverage.md` and `docs/development/manifests.md`). Similar future mechanisms may use files that live in `dev/`.

The pinned upstream Web Awesome version used by the fetch stage is stored in:

```text
dev/webawesome-version.txt
```

This file is a handwritten development input. It records the default upstream
version that `tools/fetch_webawesome.R` should retrieve when no explicit
version override is provided on the command line.

Files generated during build that report on the build live in `manifests/` and
`report/`. Current examples include API coverage and conformance tracking (see
details in `docs/development/component-coverage.md` and
`docs/development/manifests.md`) and versioned prune diagnostics written under
`report/prune/<version>/`. Future additions may store other files in these
directories.

---

# Files Excluded From the Package Build

Several directories are used during development but are not included in the final R package.

These are excluded via `.Rbuildignore`.

Examples:

```text
vendor/
tools/
docs/
dev/
manifests/
report/
journals/
scratch/
scripts/
inst/extdata/
```

Top-level repository-only files may also be excluded when they are not part of
the package build. Current examples include:

```text
AGENTS.md
.gitignore
```

This ensures that the built package only contains runtime code and assets required for users.

---

# Summary

The repository structure separates responsibilities clearly:

* top-level `R` contains both handwritten and generated package source files
* `inst/www/webawesome` contains runtime assets
* `inst/extdata/webawesome` contains build-time metadata for code generation and is excluded from the built package
* `inst/bindings` contains Shiny input bindings
* `tests/testthat` contains automated tests
* `tools` contains build scripts
* `docs` contains developer and architecture documentation
* `journals` contains workflow continuity journals
* `vendor` stores upstream source distributions
* `man` and `vignettes` contain user-facing package documentation
* `dev`, `manifests` and `report` store files used for and generated by the build process
* `scratch` and `scripts` contain local development-only materials

This layout supports a generator-driven architecture while keeping development workflows reproducible and maintainable.
