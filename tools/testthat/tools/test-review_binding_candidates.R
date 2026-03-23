# nolint start: object_usage_linter,line_length_linter.
source(file.path("..", "..", "review_binding_candidates.R"))

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.write_json <- function(path, object) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    object,
    path = path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
}

.fake_binding_review_metadata <- function() {
  list(
    schemaVersion = "1.0.0",
    package = list(name = "@awesome.me/webawesome"),
    modules = list(
      list(
        path = "components/button/button.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaButton",
            tagName = "wa-button",
            summary = "Buttons represent actions that are available to the user.",
            members = list(
              list(name = "click", kind = "method", type = list(text = "click() => void"))
            ),
            events = list(
              list(name = "focus", type = list(text = "FocusEvent"))
            )
          )
        )
      ),
      list(
        path = "components/tab/tab.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaTab",
            tagName = "wa-tab",
            summary = "Tabs act as clickable triggers that activate associated panels.",
            members = list(
              list(name = "focus", kind = "method", type = list(text = "focus() => void"))
            )
          )
        )
      ),
      list(
        path = "components/card/card.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaCard",
            tagName = "wa-card",
            summary = "Cards display grouped content."
          )
        )
      )
    )
  )
}

.create_fake_repo <- function(root) {
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(file.path(root, "inst", "extdata", "webawesome", "VERSION"), "3.3.1")
  .write_json(
    file.path(root, "inst", "extdata", "webawesome", "custom-elements.json"),
    .fake_binding_review_metadata()
  )
  .write_file(
    file.path(root, "dev", "generation", "binding-overrides.yaml"),
    c(
      "schema_version: 1",
      "",
      "components:",
      "  - tag: wa-button",
      "    binding:",
      "      mode: action",
      "      event: click",
      "      rationale: Native click semantics are expected for button-like controls."
    )
  )
}

testthat::test_that("binding review separates handled overrides from candidates", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- review_binding_candidates(root = root, verbose = FALSE)

  testthat::expect_equal(length(result$handled_overrides), 1L)
  testthat::expect_equal(result$handled_overrides[[1]]$tag, "wa-button")
  testthat::expect_equal(result$handled_overrides[[1]]$binding_source, "policy")

  testthat::expect_equal(length(result$candidates), 1L)
  testthat::expect_equal(result$candidates[[1]]$tag, "wa-tab")
  testthat::expect_true(result$candidates[[1]]$score >= 2L)
  testthat::expect_true(any(grepl(
    "interactive public methods",
    result$candidates[[1]]$reasons
  )))

  report_lines <- readLines(file.path(root, result$report_path), warn = FALSE)
  testthat::expect_true(any(grepl("^# Binding Candidate Review$", report_lines)))
  testthat::expect_true(any(grepl("^### `wa-button`$", report_lines)))
  testthat::expect_true(any(grepl("^### `wa-tab`$", report_lines)))
})
# nolint end
