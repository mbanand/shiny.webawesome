# Working Finalization Plan

This is a working development checklist for the remaining late-stage package
work. It is intentionally stored under `scratch/` because it is an active
execution plan, not authoritative project documentation.

Authoritative project documentation should be updated separately once the
relevant workflow and release process decisions are finalized.

## Status notes

- Current documented pipeline:
  `clean -> fetch -> prune -> generate -> test -> report`
- Planned pipeline extension:
  `clean -> fetch -> prune -> generate -> test -> report -> finalize -> publish`
- Current focus:
  establish the working plan, then execute it phase by phase

## A. One-Time Repo Setup

- [x] Review and finalize package identity in `DESCRIPTION`
- [x] Confirm `URL`, `BugReports`, `License`, `Authors@R`, maintainer metadata
- [x] Confirm repo URL conventions and hard-coded GitHub references
- [x] Rename `docs/` to `projectdocs/` and reserve `website/` for generated
      site output
- [x] Add baseline top-level `README.md`
- [x] Add `CODE_OF_CONDUCT.md`
- [x] Add `CONTRIBUTING.md`
- [x] Add `SECURITY.md`
- [x] Decide website hosting target and repo URL policy
- [x] Decide single sources of truth for package version and upstream Web
      Awesome version
- [ ] Review `.github/` needs for CI, release flow, and repo hygiene
- [x] Decide baseline handwritten JS lint policy:
      use `eslint` for handwritten JS only; exclude vendored upstream assets;
      avoid ad hoc formatting of generated JS
- [x] Expand `README.md` from baseline to fuller package/repo presentation
- [x] Decide whether any additional one-time repo metadata files should be
      added before release

## B. Documentation Information Architecture

- [x] Define the package documentation structure before writing content
- [x] Decide the main onboarding vignette scope:
      `Getting Started with shiny.webawesome`
- [x] Decide the supporting article list:
      `Layout Utilities`, `Shiny Bindings`, `Command API`,
      `Package Options`, `Examples`, and `Build Tools`
- [x] Map each currently deferred documentation item to a concrete page
- [x] Decide pkgdown navigation structure at a high level:
      one main onboarding vignette, user-facing articles, and a separate
      maintainer/developer area for `Build Tools` if supported cleanly
- [x] Decide where package version and upstream Web Awesome version appear on
      the website:
      both should be displayed globally in a consistent header/subheader
      location
- [x] Decide how upstream Web Awesome version is surfaced in package help pages:
      use a short standardized generated note rather than relying on custom
      help-page UI positioning

### Section B decisions

- Main vignette:
  `Getting Started with shiny.webawesome`
- Main vignette sections:
  basic wrapper usage including per-component usage and `wa_page()`;
  binding usage; command API usage; package options overview
- Supporting articles:
  `Layout Utilities`
  `Shiny Bindings`
  `Extra Attributes via htmltools`
  `Command API`
  `Package Options`
  `Examples`
  `Build Tools`
- `Examples` article shape:
  one article with 2 to 3 examples initially, split later only if needed
- `shinylive` target areas:
  likely `Layout Utilities`, `Shiny Bindings`, `Command API`, and `Examples`
- Maintainer-facing documentation:
  `Build Tools` should be grouped separately from end-user docs if pkgdown can
  support that cleanly
- Long-form docs source layout:
  `vignettes/get-started.Rmd`
  `vignettes/articles/layout-utilities.Rmd`
  `vignettes/articles/shiny-bindings.Rmd`
  `vignettes/articles/htmltools-attributes.Rmd`
  `vignettes/articles/command-api.Rmd`
  `vignettes/articles/package-options.Rmd`
  `vignettes/articles/examples.Rmd`
  `vignettes/articles/build-tools.Rmd`

## C. API Documentation Review

- [x] Review package-level documentation
- [x] Review handwritten helper roxygen
- [x] Review generated wrapper documentation for clarity and consistency
- [x] Identify any generator-driven documentation improvements still needed
- [x] Regenerate package documentation as needed with `devtools::document()`

## D. Long-Form User Documentation

- [x] Write the main onboarding vignette
- [x] Write the advanced browser glue guide
- [x] Write the extra attributes via `htmltools` guide
- [x] Write the diagnostics-control guide
- [x] Write the binding conventions guide
- [x] Write the semantic binding surface guide
- [x] Draft the `Examples` article
- [x] Draft the maintainer-facing `Build Tools` article
- [x] Review long-form docs for overlap, gaps, and stable terminology
- [x] Decide whether the current article set needs an additional dedicated
      `htmltools`-attributes page or whether that content should be folded into
      another article

## E. Website Implementation

- [x] Add and refine `_pkgdown.yml`
- [x] Configure homepage structure
- [x] Configure reference index groupings
- [x] Configure article navigation
- [x] Configure changelog/news exposure
- [x] Surface package version in the site
- [x] Surface upstream Web Awesome version in the site
- [x] Add reproducible site-build workflow/scripts

## F. Live Documentation Scope

- [x] Decide the baseline live-documentation scope
- [x] Keep package help pages non-live
- [x] Explicitly defer `webR`-based live API/man-page interactivity unless it
      becomes low-cost and clearly maintainable
- [x] Decide that `shinylive` is article-only if adopted, not reference-page
      infrastructure
- [x] Defer `shinylive` implementation from the current documentation baseline

### Section F decisions

- Package reference/help pages should remain ordinary documentation, not a
  live execution surface.
- Minimal app examples in reference docs should stay as copy-pasteable code,
  without embedded live runtime behavior.
- `pkgdown` example-result rendering should not be treated as a primary
  documentation surface for tag output, because inline rendered component
  output would add clutter without enough user value.
- `webR` integration is explicitly deferred for package help pages and man-page
  interactivity.
- If `shinylive` is adopted later, it should be limited to selected
  user-facing articles where live examples add real value.
- Article sources should remain plain R Markdown and vignette-compatible by
  default unless a later `shinylive` design proves that website-only live
  enhancements can coexist cleanly with ordinary vignette builds.

## F-1. Future `shinylive` Exploration

- [x] Prototype one article-linked `shinylive::export()` workflow using a
      standalone exported demo app
- [x] Decide whether one source can support both website live examples and
      ordinary vignette builds without excessive complexity
- [x] Decide where any `shinylive`-specific build dependencies should live:
      keep them in website-only tooling rather than package `Suggests` for now
- [x] Decide to defer `shinylive` beyond the prototype until a later package
      version, after the package and site are fully published and any wasm
      packaging path is clearer

### Section F-1 decisions

- The current prototype path is `shinylive::export()`, not Quarto embedding.
- For this repository, exported standalone demos are a better first fit than
  richer document-integrated code editing or live code execution.
- The long-form article source can remain plain R Markdown and
  vignette-compatible while linking to a separately exported live demo on the
  website.
- `shinylive` remains a docs-site concern for now, not a package-level runtime
  or documentation dependency.
- Current blocker discovered during prototyping:
  `shinylive` warns that `shiny.webawesome` is not available in the wasm binary
  repository, so the site currently publishes an explanatory placeholder page
  instead of a real live demo.
- Release decision:
  finish the current package and website using static documentation, publish
  the repo and package, and revisit `shinylive` only in a later version when a
  workable wasm-packaging path exists.

## G. Finalize Stage Definition

- [x] Define the contract for the recurring `finalize` stage
- [x] Decide which steps are mandatory versus skippable
- [x] Decide the top-level orchestrator name and interface
- [x] Decide how site builds fit into `finalize`
- [x] Decide how release-audit checks fit into `finalize`

## H. Project Documentation Updates for `finalize`

- [x] Update `projectdocs/workflow/build-pipeline.md` to include `finalize`
- [x] Update any related workflow docs that describe the late-stage package
      process
- [x] Document the boundary between `report`, `finalize`, and `publish`
- [x] Document the purpose and expected outputs of the `finalize` stage
- [x] Document which validations belong in `finalize`

## I. Finalize Stage Implementation

- [x] Add the top-level finalize orchestrator script under `tools/`
- [x] Keep finalize substeps explicit and reviewable
- [x] Support skip flags where appropriate
- [x] Ensure deterministic outputs
- [x] Add or update tests for finalize orchestration where appropriate

## J. Full Local Finalize Validation

- [ ] Run `devtools::document()`
- [ ] Run required style passes
- [ ] Run required lint passes
- [ ] Run a dependency audit for package, test, and vignette usage and review
      any `DESCRIPTION` updates intentionally rather than mutating them
      blindly
- [ ] Build vignettes/articles/site
- [ ] Run `devtools::test()`
- [ ] Run `devtools::check()`
- [ ] Run `devtools::build()`
- [ ] Run release-audit checks

## K. External Pre-Release Validation

- [ ] Review and refine GitHub Actions coverage
- [ ] Ensure Linux, macOS, and Windows validation coverage
- [ ] Add or refine remote release-oriented checks
- [ ] Run `rhub` or equivalent external pre-release checks when local finalize
      is clean

## L. Release Candidate Preparation

- [ ] Update package version in `DESCRIPTION`
- [ ] Update NEWS/changelog
- [ ] Define the release metadata flow:
      `DESCRIPTION` as the canonical package version source, git tag alignment,
      and how NEWS/release notes are derived or checked
- [ ] Confirm any mirrored version references are consistent
- [ ] Run a full `distclean` rebuild through `finalize`
- [ ] Confirm the release-candidate tarball and outputs are sane

## M. Project Documentation Updates for `publish`

- [x] Update `projectdocs/workflow/build-pipeline.md` to include `publish`
- [x] Document `publish` as distinct from `finalize`
- [x] Document the expected inputs required before `publish` can run
- [x] Document the expected publish outputs and destinations
- [x] Document which publish actions are automated versus maintainer-confirmed
- [x] Update any release/workflow docs needed so the documented pipeline is
      complete end-to-end

## N. Final Release Checklist

- [ ] Confirm git tag matches the package version
- [ ] Confirm final package tarball integrity
- [ ] Confirm all local checks passed
- [ ] Confirm all external checks passed
- [ ] Confirm documentation/site outputs are complete enough for release
- [ ] Confirm maintainer signoff items are answered affirmatively

## O. Publish

- [ ] Push repo updates and release tag
- [ ] Submit package to CRAN
- [ ] Deploy pkgdown site
- [ ] Publish any release artifacts required by the repo workflow
- [ ] Record release journal notes and any follow-up items

## Session carry-forward

At the end of each session:

- [ ] Update this checklist to reflect completed work and current focus
- [ ] Reference the current active section in the session journal
- [ ] Carry forward unfinished items and active decisions into the next journal
