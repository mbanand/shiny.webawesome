write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

create_fake_repo <- function(root) {
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools", "runners"), recursive = TRUE, showWarnings = FALSE)
  write_file(file.path(root, "DESCRIPTION"), "Package: fake")

  source_runner <- normalizePath(
    file.path("..", "..", "runners", "clean.R"),
    winslash = "/",
    mustWork = TRUE
  )
  source_stage <- normalizePath(
    file.path("..", "..", "clean_webawesome.R"),
    winslash = "/",
    mustWork = TRUE
  )
  source_cli <- normalizePath(
    file.path("..", "..", "cli_ui.R"),
    winslash = "/",
    mustWork = TRUE
  )

  file.copy(source_runner, file.path(root, "tools", "runners", "clean.R"))
  file.copy(source_stage, file.path(root, "tools", "clean_webawesome.R"))
  file.copy(source_cli, file.path(root, "tools", "cli_ui.R"))
}

run_clean_runner <- function(root, args = character()) {
  processx::run(
    "Rscript",
    c(file.path("tools", "runners", "clean.R"), args),
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("runner defaults to clean and removes generated outputs", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  dir.create(file.path(root, "R", "generated"), recursive = TRUE)
  write_file(file.path(root, "R", "generated", "wa_button.R"))

  result <- run_clean_runner(root)

  testthat::expect_equal(result$status, 0)
  testthat::expect_false(dir.exists(file.path(root, "R", "generated")))
  testthat::expect_match(result$stderr, "Clean complete: level=clean")
})

testthat::test_that("runner supports distclean", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  dir.create(file.path(root, "vendor", "webawesome"), recursive = TRUE)
  write_file(file.path(root, "vendor", "webawesome", "VERSION"))

  result <- run_clean_runner(root, c("--level", "distclean"))

  testthat::expect_equal(result$status, 0)
  testthat::expect_false(dir.exists(file.path(root, "vendor", "webawesome")))
  testthat::expect_match(result$stderr, "level=distclean")
})

testthat::test_that("runner supports dry run", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  dir.create(file.path(root, "manifests"), recursive = TRUE)
  write_file(file.path(root, "manifests", "component-coverage.yaml"))

  result <- run_clean_runner(root, "--dry-run")

  testthat::expect_equal(result$status, 0)
  testthat::expect_true(dir.exists(file.path(root, "manifests")))
  testthat::expect_true(
    file.exists(file.path(root, "manifests", "component-coverage.yaml"))
  )
  testthat::expect_match(result$stderr, "Dry run complete: level=clean")
})

testthat::test_that("runner supports quiet mode", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  dir.create(file.path(root, "R", "generated"), recursive = TRUE)
  write_file(file.path(root, "R", "generated", "wa_button.R"))

  result <- run_clean_runner(root, "--quiet")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stderr, "Clean complete: level=clean")
})

testthat::test_that("runner prints help", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  result <- run_clean_runner(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: Rscript tools/runners/clean.R")
  testthat::expect_match(result$stdout, "Options:")
  testthat::expect_match(result$stdout, "--dry-run")
})

testthat::test_that("runner rejects unknown arguments", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  result <- run_clean_runner(root, "--bogus")

  testthat::expect_true(result$status != 0)
  testthat::expect_match(result$stderr, "Unknown argument: --bogus")
})

testthat::test_that("runner rejects missing level values", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  result <- run_clean_runner(root, "--level")

  testthat::expect_true(result$status != 0)
  testthat::expect_match(result$stderr, "Missing value for --level.")
})

testthat::test_that("runner rejects invalid level values", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  result <- run_clean_runner(root, c("--level", "bogus"))

  testthat::expect_true(result$status != 0)
  testthat::expect_match(
    result$stderr,
    "should be one of"
  )
})
