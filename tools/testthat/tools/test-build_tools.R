.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root) {
  dir.create(file.path(root, "projectdocs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")

  file.copy(
    normalizePath(file.path("..", "..", "build_tools.R"), mustWork = TRUE),
    file.path(root, "tools", "build_tools.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  .write_file(file.path(root, "tools", "test_tools.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('test tools invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "document_tools.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('document tools invoked\\n')"
  ))
  Sys.chmod(file.path(root, "tools", "build_tools.R"), mode = "0755")
  Sys.chmod(file.path(root, "tools", "test_tools.R"), mode = "0755")
  Sys.chmod(file.path(root, "tools", "document_tools.R"), mode = "0755")
}

.run_build_tools_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/build_tools.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("build_tools prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_tools_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/build_tools.R")
  testthat::expect_match(result$stdout, "--skip-tests")
  testthat::expect_match(result$stdout, "--skip-docs")
})

testthat::test_that("build_tools runs tests and docs by default", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_tools_script(root)

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stderr, "Testing tools")
  testthat::expect_match(result$stderr, "Testing tools \\.{2,} Pass")
  testthat::expect_match(result$stderr, "Documenting tools")
  testthat::expect_match(result$stderr, "Documenting tools \\.{2,} Done")
})

testthat::test_that("build_tools supports skipping tests or docs", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  skip_tests <- .run_build_tools_script(root, "--skip-tests")
  skip_docs <- .run_build_tools_script(root, "--skip-docs")

  testthat::expect_equal(skip_tests$status, 0)
  testthat::expect_no_match(skip_tests$stderr, "Testing tools")
  testthat::expect_match(skip_tests$stderr, "Documenting tools \\.{2,} Done")

  testthat::expect_equal(skip_docs$status, 0)
  testthat::expect_match(skip_docs$stderr, "Testing tools \\.{2,} Pass")
  testthat::expect_no_match(skip_docs$stderr, "Documenting tools")
})
