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
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")

  file.copy(
    normalizePath(file.path("..", "..", "build_package.R"), mustWork = TRUE),
    file.path(root, "tools", "build_package.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  .write_file(file.path(root, "tools", "build_tools.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('build tools invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "fetch_webawesome.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('fetch invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "prune_webawesome.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('prune invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "generate_components.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('generate invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "review_binding_candidates.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('review invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "report_components.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('report invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "check_integrity.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('integrity invoked\\n')"
  ))
  Sys.chmod(file.path(root, "tools", "build_package.R"), mode = "0755")
  Sys.chmod(file.path(root, "tools", "build_tools.R"), mode = "0755")
  Sys.chmod(file.path(root, "tools", "fetch_webawesome.R"), mode = "0755")
  Sys.chmod(file.path(root, "tools", "prune_webawesome.R"), mode = "0755")
  Sys.chmod(file.path(root, "tools", "generate_components.R"), mode = "0755")
  Sys.chmod(
    file.path(root, "tools", "review_binding_candidates.R"),
    mode = "0755"
  )
  Sys.chmod(file.path(root, "tools", "report_components.R"), mode = "0755")
  Sys.chmod(file.path(root, "tools", "check_integrity.R"), mode = "0755")
}

.run_build_package_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/build_package.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("build_package prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_package_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/build_package.R")
  testthat::expect_match(result$stdout, "--skip-tools")
})

testthat::test_that("build_package runs build_tools first when present", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_package_script(root)

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stderr, "Building tools \\.{2,} Done")
  testthat::expect_match(
    result$stderr,
    "Running fetch_webawesome\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running prune_webawesome\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running generate_components\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running review_binding_candidates\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running report_components\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running check_integrity\\.R \\.{2,} Done"
  )
})

testthat::test_that("build_package supports skipping the tool workflow", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_package_script(root, "--skip-tools")

  testthat::expect_equal(result$status, 0)
  testthat::expect_no_match(result$stderr, "Building tools")
  testthat::expect_match(
    result$stderr,
    "Running fetch_webawesome\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running prune_webawesome\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running generate_components\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running review_binding_candidates\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running report_components\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running check_integrity\\.R \\.{2,} Done"
  )
})
