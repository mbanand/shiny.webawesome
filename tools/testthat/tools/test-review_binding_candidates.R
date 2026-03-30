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
            summary = "Tabs act as triggers that activate associated panels.",
            members = list(
              list(name = "focus", kind = "method", type = list(text = "focus() => void"))
            )
          )
        )
      ),
      list(
        path = "components/trigger/trigger.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaTrigger",
            tagName = "wa-trigger",
            summary = "Triggers activate actions when the user clicks them.",
            members = list(
              list(name = "click", kind = "method", type = list(text = "click() => void")),
              list(name = "focus", kind = "method", type = list(text = "focus() => void"))
            )
          )
        )
      ),
      list(
        path = "components/tooltip/tooltip.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaTooltip",
            tagName = "wa-tooltip",
            summary = "Tooltips show additional information on hover or focus.",
            members = list(
              list(name = "show", kind = "method", type = list(text = "show() => void")),
              list(name = "hide", kind = "method", type = list(text = "hide() => void"))
            )
          )
        )
      ),
      list(
        path = "components/switch/switch.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaSwitch",
            tagName = "wa-switch",
            summary = "Switches allow the user to toggle an option on or off.",
            members = list(
              list(name = "click", kind = "method", type = list(text = "click() => void"))
            ),
            attributes = list(
              list(name = "checked", fieldName = "defaultChecked", type = list(text = "boolean"))
            ),
            events = list(
              list(name = "change", type = list(text = "Event"))
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
  .write_file(
    file.path(root, "R", "wa_warning_registry.R"),
    c(
      ".wa_warning_defaults <- function() {",
      "  list(",
      "    missing_tree_item_id = TRUE",
      "  )",
      "}",
      "",
      ".wa_warning_keys <- function() {",
      "  names(.wa_warning_defaults())",
      "}"
    )
  )
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

testthat::test_that("binding review separates overrides, candidates, watch list, and exclusions", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- review_binding_candidates(root = root, verbose = FALSE)

  testthat::expect_equal(length(result$handled_overrides), 1L)
  testthat::expect_equal(result$handled_overrides[[1]]$tag, "wa-button")
  testthat::expect_equal(result$handled_overrides[[1]]$binding_source, "policy")

  testthat::expect_equal(length(result$candidates), 1L)
  testthat::expect_equal(result$candidates[[1]]$tag, "wa-trigger")
  testthat::expect_equal(result$candidates[[1]]$review_tier, "candidate")
  testthat::expect_true(any(grepl(
    "public click\\(\\) method without declared binding event",
    result$candidates[[1]]$reasons
  )))

  testthat::expect_equal(length(result$watch_list), 1L)
  testthat::expect_equal(result$watch_list[[1]]$tag, "wa-tab")
  testthat::expect_equal(result$watch_list[[1]]$review_tier, "watch")
  testthat::expect_true(any(grepl(
    "directly activated control",
    result$watch_list[[1]]$reasons
  )))

  surfaced_tags <- c(
    vapply(result$candidates, `[[`, character(1), "tag"),
    vapply(result$watch_list, `[[`, character(1), "tag")
  )
  testthat::expect_false("wa-tooltip" %in% surfaced_tags)
  testthat::expect_false("wa-switch" %in% surfaced_tags)

  report_lines <- readLines(file.path(root, result$report_path), warn = FALSE)
  testthat::expect_true(any(grepl("^# Binding Candidate Review$", report_lines)))
  testthat::expect_true(any(grepl("^### `wa-button`$", report_lines)))
  testthat::expect_true(any(grepl("^### `wa-tab`$", report_lines)))
  testthat::expect_true(any(grepl("^### `wa-trigger`$", report_lines)))
  testthat::expect_true(any(grepl("^## Watch List / Near Misses$", report_lines)))
})
# nolint end
