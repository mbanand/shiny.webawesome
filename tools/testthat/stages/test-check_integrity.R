# nolint start: object_usage_linter.
source(file.path("..", "..", "check_integrity.R"))

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root) {
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
}

testthat::test_that("check_integrity passes for matching recorded surfaces", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  .write_file(
    file.path(root, "inst", "extdata", "webawesome", "VERSION"),
    "3.3.1"
  )
  .write_file(
    file.path(root, "inst", "www", "wa", "webawesome.loader.js"),
    "export const loader = true;"
  )
  .write_file(
    file.path(root, "R", "wa_button.R"),
    c(.generated_file_marker(), "wa_button <- function(...) NULL")
  )
  .write_file(
    file.path(root, "inst", "bindings", "wa_button.js"),
    "export default true;"
  )

  prune_record <- .write_prune_integrity(root)
  generate_record <- .write_generate_integrity(root)

  testthat::expect_true(file.exists(file.path(root, prune_record$path)))
  testthat::expect_true(file.exists(file.path(root, generate_record$path)))

  result <- check_integrity(root = root, verbose = FALSE)

  testthat::expect_true(result$checks$prune_output$ok)
  testthat::expect_true(result$checks$generate_output$ok)
  testthat::expect_equal(result$written$summary, "reports/integrity/summary.md")
  testthat::expect_true(file.exists(file.path(root, result$written$summary)))
})

testthat::test_that("check_integrity fails for drifted generated surfaces", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  .write_file(
    file.path(root, "inst", "extdata", "webawesome", "VERSION"),
    "3.3.1"
  )
  .write_file(
    file.path(root, "inst", "www", "wa", "webawesome.loader.js"),
    "export const loader = true;"
  )
  .write_file(
    file.path(root, "R", "wa_button.R"),
    c(.generated_file_marker(), "wa_button <- function(...) NULL")
  )
  .write_file(
    file.path(root, "inst", "bindings", "wa_button.js"),
    "export default true;"
  )

  .write_prune_integrity(root)
  .write_generate_integrity(root)
  .write_file(
    file.path(root, "R", "wa_button.R"),
    c(.generated_file_marker(), "wa_button <- function(...) 1")
  )

  summary_path <- file.path(root, "reports", "integrity", "summary.md")
  testthat::expect_error(
    check_integrity(root = root, verbose = FALSE),
    "current generate surface checksums differ from recorded generate output"
  )
  testthat::expect_true(file.exists(summary_path))
  testthat::expect_true(any(grepl(
    "current generate surface checksums differ from recorded generate output",
    readLines(summary_path, warn = FALSE),
    fixed = TRUE
  )))
})
# nolint end
