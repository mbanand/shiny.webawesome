source(file.path("..", "..", "finalize_package.R"))

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root) {
  dir.create(
    file.path(root, "projectdocs"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)

  .write_file(file.path(root, "DESCRIPTION"), c(
    "Package: fake",
    "Version: 0.1.0"
  ))

  file.copy(
    normalizePath(file.path("..", "..", "finalize_package.R"), mustWork = TRUE),
    file.path(root, "tools", "finalize_package.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "integrity.R"), mustWork = TRUE),
    file.path(root, "tools", "integrity.R")
  )

  Sys.chmod(file.path(root, "tools", "finalize_package.R"), mode = "0755")
}

.run_finalize_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/finalize_package.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("finalize_package prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_finalize_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/finalize_package.R")
  testthat::expect_match(result$stdout, "--strict")
  testthat::expect_match(result$stdout, "--confirmed-rhub-pass")
  testthat::expect_match(result$stdout, "--confirmed-visual-review")
  testthat::expect_match(result$stdout, "--quiet")
})

testthat::test_that("finalize_package rejects unknown arguments", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_finalize_script(root, "--bogus")

  testthat::expect_false(identical(result$status, 0L))
  testthat::expect_match(result$stderr, "Unknown argument")
})

testthat::test_that(
  "finalize_package strict mode no longer enforces clean start state",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)
    dir.create(file.path(root, "vendor", "webawesome"), recursive = TRUE)

    result <- .run_finalize_script(root, "--strict")

    testthat::expect_false(identical(result$status, 0L))
    testthat::expect_no_match(
      result$stderr,
      "Strict finalize requires a clean release-build starting state"
    )
    testthat::expect_match(result$stderr, "check_integrity\\.R")
  }
)
