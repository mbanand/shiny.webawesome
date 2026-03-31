.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root) {
  dir.create(file.path(root, "projectdocs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(
    file.path(root, "tools", "testthat", "tools"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")

  file.copy(
    normalizePath(file.path("..", "..", "test_tools.R"), mustWork = TRUE),
    file.path(root, "tools", "test_tools.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  .write_file(file.path(root, "tools", "testthat", "tools", "test-alpha.R"), c(
    "testthat::test_that('alpha', {",
    "  testthat::expect_true(TRUE)",
    "})"
  ))
}

.run_test_tools_runner <- function(root, args = character()) {
  processx::run(
    "Rscript",
    c(file.path("tools", "test_tools.R"), args),
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("tool test runner prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_test_tools_runner(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: Rscript tools/test_tools.R")
  testthat::expect_match(result$stdout, "Options:")
  testthat::expect_match(result$stdout, "--filter")
})

testthat::test_that("tool test runner rejects unknown arguments", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_test_tools_runner(root, "--bogus")

  testthat::expect_true(result$status != 0)
  testthat::expect_match(result$stderr, "Unknown argument: --bogus")
})

testthat::test_that("tool test runner filters discovered test files", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_test_tools_runner(root, "--filter=alpha")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stderr, "Testing tools")
  testthat::expect_match(result$stderr, "alpha")
  testthat::expect_match(result$stderr, "pass")
})
