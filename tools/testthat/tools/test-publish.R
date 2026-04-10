source(file.path("..", "..", "publish.R"))

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
    normalizePath(file.path("..", "..", "publish.R"), mustWork = TRUE),
    file.path(root, "tools", "publish.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "integrity.R"), mustWork = TRUE),
    file.path(root, "tools", "integrity.R")
  )

  Sys.chmod(file.path(root, "tools", "publish.R"), mode = "0755")
}

.run_publish_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/publish.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("publish prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_publish_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/publish.R")
  testthat::expect_match(result$stdout, "--release-version")
  testthat::expect_match(result$stdout, "--dry-run")
  testthat::expect_match(result$stdout, "--do-tag")
  testthat::expect_match(result$stdout, "--deploy-site")
})

testthat::test_that("publish rejects unknown arguments", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_publish_script(root, "--bogus")

  testthat::expect_false(identical(result$status, 0L))
  testthat::expect_match(result$stderr, "Unknown argument")
})
