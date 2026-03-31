source(file.path("..", "..", "document_tools.R"))

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root) {
  dir.create(file.path(root, "projectdocs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(
    file.path(root, "tools", "generate"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  .write_file(file.path(root, "DESCRIPTION"), c(
    "Package: fake",
    "Title: Fake",
    "Version: 0.0.0.9000",
    "Description: Fake package.",
    "License: MIT + file LICENSE",
    "Encoding: UTF-8",
    "Roxygen: list(markdown = TRUE)"
  ))
  .write_file(file.path(root, "LICENSE"), "MIT")
  file.copy(
    normalizePath(file.path("..", "..", "document_tools.R"), mustWork = TRUE),
    file.path(root, "tools", "document_tools.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "build_package.R"), mustWork = TRUE),
    file.path(root, "tools", "build_package.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "build_tools.R"), mustWork = TRUE),
    file.path(root, "tools", "build_tools.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "check_integrity.R"), mustWork = TRUE),
    file.path(root, "tools", "check_integrity.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "integrity.R"), mustWork = TRUE),
    file.path(root, "tools", "integrity.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "clean_webawesome.R"), mustWork = TRUE),
    file.path(root, "tools", "clean_webawesome.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "fetch_webawesome.R"), mustWork = TRUE),
    file.path(root, "tools", "fetch_webawesome.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "prune_webawesome.R"), mustWork = TRUE),
    file.path(root, "tools", "prune_webawesome.R")
  )
  file.copy(
    normalizePath(
      file.path("..", "..", "report_components.R"),
      mustWork = TRUE
    ),
    file.path(root, "tools", "report_components.R")
  )
  file.copy(
    normalizePath(
      file.path("..", "..", "review_binding_candidates.R"),
      mustWork = TRUE
    ),
    file.path(root, "tools", "review_binding_candidates.R")
  )
  helper_files <- c("utils.R", "policy.R", "metadata.R", "schema.R")
  for (helper in helper_files) {
    file.copy(
      normalizePath(
        file.path("..", "..", "generate", helper),
        mustWork = TRUE
      ),
      file.path(root, "tools", "generate", helper)
    )
  }
  file.copy(
    normalizePath(file.path("..", "..", "test_tools.R"), mustWork = TRUE),
    file.path(root, "tools", "test_tools.R")
  )
}

testthat::test_that("document_tools generates docs into tools/man", {
  testthat::skip_if_not_installed("document")
  withr::local_envvar(c(SHINY_WEBAWESOME_CLI_MODE = "quiet"))

  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- document_tools(
    files = "tools/clean_webawesome.R",
    root = root,
    verbose = FALSE
  )

  testthat::expect_true(dir.exists(file.path(root, "tools", "man")))
  testthat::expect_true(any(grepl("\\.Rd$", result$generated)))
  testthat::expect_true(any(grepl("\\.txt$", result$generated)))
  testthat::expect_true(any(grepl("\\.html$", result$generated)))
  testthat::expect_true(
    file.exists(file.path(root, "tools", "man", "clean_webawesome.Rd"))
  )
})

testthat::test_that(
  "document_tools default file set includes fetch and prune stages",
  {
    testthat::skip_if_not_installed("document")
    withr::local_envvar(c(SHINY_WEBAWESOME_CLI_MODE = "quiet"))

    root <- withr::local_tempdir()
    .create_fake_repo(root)

    result <- document_tools(root = root, verbose = FALSE)

    testthat::expect_true("fetch_webawesome.Rd" %in% result$generated)
    testthat::expect_true("check_integrity.Rd" %in% result$generated)
    testthat::expect_true("prune_webawesome.Rd" %in% result$generated)
    testthat::expect_true("report_components.Rd" %in% result$generated)
    testthat::expect_true("review_binding_candidates.Rd" %in% result$generated)
    testthat::expect_true(
      file.exists(file.path(root, "tools", "man", "fetch_webawesome.Rd"))
    )
    testthat::expect_true(
      file.exists(file.path(root, "tools", "man", "check_integrity.Rd"))
    )
    testthat::expect_true(
      file.exists(file.path(root, "tools", "man", "prune_webawesome.Rd"))
    )
    testthat::expect_true(
      file.exists(file.path(root, "tools", "man", "report_components.Rd"))
    )
    testthat::expect_true(
      file.exists(file.path(
        root,
        "tools",
        "man",
        "review_binding_candidates.Rd"
      ))
    )
  }
)

testthat::test_that("document_tools rejects missing source files", {
  testthat::skip_if_not_installed("document")
  withr::local_envvar(c(SHINY_WEBAWESOME_CLI_MODE = "quiet"))

  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    document_tools(files = "tools/missing.R", root = root, verbose = FALSE),
    "Tool documentation source files do not exist"
  )
})
