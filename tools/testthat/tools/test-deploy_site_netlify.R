source(file.path("..", "..", "deploy_site_netlify.R"))

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
  dir.create(file.path(root, "website"), recursive = TRUE, showWarnings = FALSE)

  .write_file(file.path(root, "DESCRIPTION"), c(
    "Package: fake",
    "Version: 0.1.0"
  ))

  file.copy(
    normalizePath(
      file.path("..", "..", "deploy_site_netlify.R"),
      mustWork = TRUE
    ),
    file.path(root, "tools", "deploy_site_netlify.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )

  Sys.chmod(file.path(root, "tools", "deploy_site_netlify.R"), mode = "0755")
}

.run_deploy_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/deploy_site_netlify.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("deploy_site_netlify prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_deploy_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(
    result$stdout,
    "Usage: ./tools/deploy_site_netlify.R"
  )
  testthat::expect_match(result$stdout, "--dry-run")
})

testthat::test_that("deploy_site_netlify rejects unknown arguments", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_deploy_script(root, "--bogus")

  testthat::expect_false(identical(result$status, 0L))
  testthat::expect_match(result$stderr, "Unknown argument")
})
